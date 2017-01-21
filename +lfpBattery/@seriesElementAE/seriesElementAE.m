classdef seriesElementAE < lfpBattery.seriesElement
    %SERIESELEMENTAE battery elements connected in series with active
    %equalization
    
    properties (Dependent)
        V;
    end
    properties (Dependent, SetAccess = 'protected')
        Cd;
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
            % Pass v on to all elements to account balancing
            [b.El.V] = deal(v);
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

