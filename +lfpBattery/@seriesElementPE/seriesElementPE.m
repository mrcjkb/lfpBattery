classdef seriesElementPE < lfpBattery.seriesElement
    %SERIESELEMENTPE battery elements connected in series with passive
    %equalization
    
    properties (Dependent, SetAccess = 'protected')
        Cd;
    end
    
    methods
        function b = seriesElementPE(varargin)
            b@lfpBattery.seriesElement(varargin{:})
        end
        function c = get.Cd(b)
            % total capacity = min of elements' capacities
            % --> discharged capacity = min of elements' discharged
            % capacities, since chargeable capacity is limited with passive
            % equalization
            c = min([b.El.Cd]);
        end
    end
    
    methods (Access = 'protected')
        function refreshNominals(b)
            b.Vn = sum([b.El.Vn]);
            b.Cn = min([b.El.Cn]);
        end 
    end
end

