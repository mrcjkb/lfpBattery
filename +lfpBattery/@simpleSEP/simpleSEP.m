classdef simpleSEP < lfpBattery.simpleSE
    %SIMPLESEP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        V;
    end
    
    methods
        function v = get.V(b)
            v = b.nEl .* b.El.V;
        end
        function set.V(b, v)
            
            % set voltages according to proportions of internal impedances
            p = b.getZProportions;
            v = v .* p(:);
            for i = uint32(1):b.nEl
                b.El(i).V = v(i);
            end
        end
    end
    
    methods (Access = 'protected')
        function refreshNominals(b)
            b.Vn = sum([b.El.Vn]);
            b.Cn = min([b.El.Cn]);
        end
        function s = sohCalc(b)
            s = min([b.El.SoH]);
        end
        function c = dummyCharge(b, Q)
            c = min(dummyCharge@lfpBattery.seriesElement(b, Q));
        end
    end
    
end

