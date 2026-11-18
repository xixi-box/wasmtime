;;! exceptions = true

;; A destructor exception must trap at resource.drop, before the caller
;; can catch it, including when guest debugging uses libcall traps.
;; tests/all/debug.rs also runs this script with guest debugging enabled.
(component
  (component $A
    (core module $dtor
      (tag $t)
      (func (export "dtor") (param i32) (throw $t)))
    (core instance $dtor (instantiate $dtor))
    (type $t (resource (rep i32) (dtor (core func $dtor "dtor"))))
    (core func $t.new (canon resource.new $t))
    (export $t' "t" (type $t))
    (func (export "new") (param "rep" u32) (result (own $t'))
      (canon lift (core func $t.new))))

  (component $B
    (import "a" (instance $a
      (export "t" (type $t (sub resource)))
      (export "new" (func (param "rep" u32) (result (own $t))))))
    (core func $new (canon lower (func $a "new")))
    (alias export $a "t" (type $t))
    (core func $t.drop (canon resource.drop $t))
    (core module $b
      (import "" "new" (func $new (param i32) (result i32)))
      (import "" "t.drop" (func $t.drop (param i32)))
      (func (export "run")
        (block $caught
          (try_table (catch_all $caught)
            (call $t.drop (call $new (i32.const 0))))
          (return))
        unreachable))
    (core instance $b (instantiate $b
      (with "" (instance
        (export "new" (func $new))
        (export "t.drop" (func $t.drop))))))
    (func (export "run") (canon lift (core func $b "run"))))

  (instance $a (instantiate $A))
  (instance $b (instantiate $B (with "a" (instance $a))))
  (export "run" (func $b "run")))

(assert_trap (invoke "run") "uncaught exception propagated out of component")

;; A destructor may catch its own exception and return normally. Repeated
;; calls also check that successful drops restore the caller's state.
(component
  (component $A
    (core module $dtor
      (tag $t)
      (func (export "dtor") (param i32)
        (block $caught
          (try_table (catch_all $caught) (throw $t)))))
    (core instance $dtor (instantiate $dtor))
    (type $t (resource (rep i32) (dtor (core func $dtor "dtor"))))
    (core func $t.new (canon resource.new $t))
    (export $t' "t" (type $t))
    (func (export "new") (param "rep" u32) (result (own $t'))
      (canon lift (core func $t.new))))

  (component $B
    (import "a" (instance $a
      (export "t" (type $t (sub resource)))
      (export "new" (func (param "rep" u32) (result (own $t))))))
    (core func $new (canon lower (func $a "new")))
    (alias export $a "t" (type $t))
    (core func $t.drop (canon resource.drop $t))
    (core module $b
      (import "" "new" (func $new (param i32) (result i32)))
      (import "" "t.drop" (func $t.drop (param i32)))
      (func (export "run")
        (block $caught
          (try_table (catch_all $caught)
            (call $t.drop (call $new (i32.const 0))))
          (return))
        unreachable))
    (core instance $b (instantiate $b
      (with "" (instance
        (export "new" (func $new))
        (export "t.drop" (func $t.drop))))))
    (func (export "run") (canon lift (core func $b "run"))))

  (instance $a (instantiate $A))
  (instance $b (instantiate $B (with "a" (instance $a))))
  (export "run" (func $b "run")))

(assert_return (invoke "run"))
(assert_return (invoke "run"))

;; Dropping a resource with no destructor still returns normally.
(component
  (component $A
    (type $t (resource (rep i32)))
    (core func $t.new (canon resource.new $t))
    (export $t' "t" (type $t))
    (func (export "new") (param "rep" u32) (result (own $t'))
      (canon lift (core func $t.new))))

  (component $B
    (import "a" (instance $a
      (export "t" (type $t (sub resource)))
      (export "new" (func (param "rep" u32) (result (own $t))))))
    (core func $new (canon lower (func $a "new")))
    (alias export $a "t" (type $t))
    (core func $t.drop (canon resource.drop $t))
    (core module $b
      (import "" "new" (func $new (param i32) (result i32)))
      (import "" "t.drop" (func $t.drop (param i32)))
      (func (export "run")
        (block $caught
          (try_table (catch_all $caught)
            (call $t.drop (call $new (i32.const 0))))
          (return))
        unreachable))
    (core instance $b (instantiate $b
      (with "" (instance
        (export "new" (func $new))
        (export "t.drop" (func $t.drop))))))
    (func (export "run") (canon lift (core func $b "run"))))

  (instance $a (instantiate $A))
  (instance $b (instantiate $B (with "a" (instance $a))))
  (export "run" (func $b "run")))

(assert_return (invoke "run"))
(assert_return (invoke "run"))
