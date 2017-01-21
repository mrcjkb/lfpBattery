classdef seriesElementPE < lfpBattery.seriesElement
    %SERIESELEMENTPE battery elements connected in series with passive
    %equalization
    
    properties (Dependent)
        V; % Resting voltage / V
    end
    properties (Dependent, SetAccess = 'protected')
        % Discharge capacity in Ah (Cd = 0 if SoC = 1).
        % The discharge capacity is given by the nominal capacity Cn and
        % the current capacity C at SoC.
        % Cd = Cn - C
        Cd;
        % Current capacity level in Ah.
        C;
    end
    
    methods
        function b = seriesElementPE(varargin)
            b@lfpBattery.seriesElement(varargin{:})
        end
        function v = get.V(b)
            v = sum([b.El.V]);
        end
        function c = get.Cd(b)
            % total capacity = min of elements' capacities
            % --> discharged capacity = min of elements' discharged
            % capacities, since chargeable capacity is limited with passive
            % equalization
            c = b.Cn - b.C;
        end
        function c = get.C(b)
            c = min([b.El.C]);
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

