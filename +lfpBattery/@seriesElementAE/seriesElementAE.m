classdef seriesElementAE < lfpBattery.seriesElement
    %SERIESELEMENTAE battery elements connected in series with active
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
        function b = seriesElementAE(varargin)
            b@lfpBattery.seriesElement(varargin{:})
        end
        function v = get.V(b)
            v = sum([b.El.V]);
        end
        function c = get.Cd(b)
            c = mean([b.El.Cd]);
        end
        function c = get.C(b)
            c = mean([b.El.C]);
        end
        function set.V(b, v)
            % Pass v on to all elements equally to account for balancing
            [b.El.V] = deal(v ./ double(b.nEl));
        end
    end
    
    methods (Access = 'protected')
        function refreshNominals(b)
            b.Vn = sum([b.El.Vn]);
            b.Cn = mean([b.El.Cn]);
        end 
        function s = sohCalc(b)
            s = mean([b.El.SoH]); 
        end
        function c = dummyCharge(b, Q)
            c = mean(dummyCharge@lfpBattery.seriesElement(b, Q));
        end
    end
    
end

