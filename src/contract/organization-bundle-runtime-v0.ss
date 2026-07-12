(export #t)

(import :clan/poo/object
        :poo-flow/src/semantic/organization-bundle
        :poo-flow/src/semantic/organization-bundle-kernel)

(def +poo-flow-runtime-v0-control-packet-schema+
  'poo-flow.runtime-v0.control-packet.1)

(def (poo-flow-runtime-v0-control-packet state)
  (unless (and (object? state)
               (memq (.ref state 'phase) '(validated advanced)))
    (error "runtime v0 control packet requires validated Bundle Kernel state"
           state))
  (let ((identity (.ref state 'identity))
        (bundle (.ref state 'bundle)))
    (.o (kind +poo-flow-runtime-v0-control-packet-schema+)
        (abi-major 0)
        (abi-minor 1)
        (bundle-schema +poo-flow-organization-bundle-schema+)
        (digest-algorithm (.ref identity 'algorithm))
        (bundle-digest (.ref identity 'digest))
        (bundle-epoch (.ref bundle 'epoch))
        (kernel-epoch (.ref state 'epoch))
        (canonical-packet (.ref state 'canonical-payload))
        (abi-v1-frozen? #f))))

(def (poo-flow-runtime-v0-control-packet->alist packet)
  (list (cons 'kind (.ref packet 'kind))
        (cons 'abi-major (.ref packet 'abi-major))
        (cons 'abi-minor (.ref packet 'abi-minor))
        (cons 'bundle-schema (.ref packet 'bundle-schema))
        (cons 'digest-algorithm (.ref packet 'digest-algorithm))
        (cons 'bundle-digest (.ref packet 'bundle-digest))
        (cons 'bundle-epoch (.ref packet 'bundle-epoch))
        (cons 'kernel-epoch (.ref packet 'kernel-epoch))
        (cons 'canonical-packet (.ref packet 'canonical-packet))
        (cons 'abi-v1-frozen? (.ref packet 'abi-v1-frozen?))))
