# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Build the optional native ASCENT provider from a fixed committed source.

No dirty provider checkout or package uninstall is used. Caller supplies the
qualified POO dependency environment. Each actual compiler stage emits progress.
"""
import argparse,hashlib,io,json,os,re,subprocess,sys,tarfile
from pathlib import Path
PIN='74f0046bb6137b4fce22db5ae398b9812734c137'
REPO=Path(__file__).resolve().parents[2]

def prepare(repository,output):
    output=Path(output).resolve();output.mkdir(exist_ok=False)
    source=output/'source/gerbil-ascent';source.mkdir(parents=True)
    archive=subprocess.check_output(['git','-C',str(repository),'archive',PIN])
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:tar.extractall(source,filter='data')
    library=output/'native/lib';library.mkdir(parents=True)
    compiler=output/'clang-native'
    compiler.write_text('#!/bin/sh\nexec /usr/bin/clang "$@" -O0 -bundle -fPIC\n')
    compiler.chmod(0o755)
    env=dict(os.environ,GERBIL_PATH=str(output/'native'),CC='/usr/bin/clang',BUILD_DYN_CC_PARAM=str(compiler))
    env.pop('SDKROOT',None)
    env['GERBIL_LOADPATH']=':'.join([str(library),str(output/'source'),env.get('GERBIL_LOADPATH','')])
    done=set();active=set();modules=[]
    def compile_module(name):
        if name in done:return
        if name in active:raise ValueError('native import cycle: '+name)
        active.add(name);path=source/(name+'.ss');text=path.read_text()
        deps=re.findall(r':gerbil-ascent/([\w/-]+)',text)
        for relative in re.findall(r'"([\w./-]+\.ss)"',text):
            candidate=(path.parent/relative).resolve()
            if candidate.is_relative_to(source) and candidate.exists():deps.append(str(candidate.relative_to(source))[:-3])
        for dependency in dict.fromkeys(deps):compile_module(dependency)
        active.remove(name);done.add(name);modules.append(name)
    compile_module('candidate/reasoning')
    paths=[source/(name+'.ss') for name in modules]
    base=REPO/'modules/temporal-causality/candidates/ascent'
    paths += [base/(name+'.ss') for name in ('types','objects','funs','interface','runtime')]
    paths += [REPO/'modules/temporal-causality'/(name+'.ss') for name in ('candidates/interface','interface')]
    preload='(port-settings-set! (current-output-port) (list buffering: #f)) (load "scripts/temporal/preload.ss") (temporal-preload-module "core/types") (temporal-preload-module "gerbil/compiler") (temporal-preload-module "poo-flow/scripts/temporal/exit-child-process")'
    code='(begin (import :gerbil/compiler :poo-flow/scripts/temporal/exit-child-process)'
    for path in paths:
        quoted=json.dumps(str(path))
        code += ' (displayln "COMPILE " '+quoted+') (force-output) (compile-module '+quoted+' (list verbose: #t optimize: #f invoke-gsc: #t gsc-options: (list "-verbose" "-cc-options" "-O0 -bundle -fPIC") output-dir: '+json.dumps(str(library))+')) (displayln "COMPILED " '+quoted+') (force-output)'
    code += ' (temporal-child-process-exit! 0))'
    subprocess.run(['gxi','-e',preload,'-e',code],env=env,cwd=REPO,check=True,timeout=300)
    expected=[library/'gerbil-ascent'/(name+'.ssi') for name in modules]
    expected += [library/'poo-flow'/path.relative_to(REPO).with_suffix('.ssi') for path in paths[len(modules):]]
    for artifact in expected:
        if not artifact.is_file() or not artifact.with_suffix('.o1').is_file():
            raise RuntimeError('compiler produced no native interface/object: '+str(artifact))
    (output/'build.json').write_text(json.dumps(dict(provider_pin=PIN,modules=modules,library=str(library),optimization=False,
        native_compiler='/usr/bin/clang',c_optimization='-O0',
        artifacts={str(path.relative_to(library)): hashlib.sha256(path.read_bytes()).hexdigest() for artifact in expected for path in (artifact,artifact.with_suffix('.o1'))},
        sources={str(path.relative_to(REPO)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths[len(modules):]}),indent=2)+'\n')
    return env

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('repository');parser.add_argument('output')
    parser.add_argument('--qualify',action='store_true')
    args=parser.parse_args();env=prepare(Path(args.repository),args.output)
    if args.qualify:
        subprocess.run([sys.executable,str(REPO/'scripts/temporal/check_ascent_runtime.py'),str(Path(args.output).resolve())],env=env,cwd=REPO,check=True,timeout=300)
