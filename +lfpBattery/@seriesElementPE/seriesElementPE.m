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
            c = max([b.El.Cd]); % total = Cn - min capacity = max discharge capacity
        end
    end
    
    methods (Access = 'protected')
        function refreshNominals(b)
            b.Vn = sum([b.El.Vn]);
            b.Cn = min([b.El.Cn]);
        end 
    end
end

