require 'mobiruby'

        
class Cocoa::MobiTests < Cocoa::GHTestCase
    define C::Void, :testSimplePass do
        p "AAAA2"
        assert(false, "OK!")
        p "BBBB"
    end

    #define C::Void, :assert, C::Int, C::Pointer do |expr, description|
    def assert(expr, description)

        unless expr
            e = CFunc::call(Cocoa::Object, "gh_assert", description)
            p e
#p        e=CFunc::call(Cocoa::Object, "test123", "123")
            self._failWithException CFunc::call(Cocoa::Object, "test123", "123")
        end
    end
end
