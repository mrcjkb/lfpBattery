classdef seriesElementAE < lfpBattery.seriesElement
    %SERIESELEMENTAE battery elements connected in series with active
    %equalization
    
    properties (Dependent, SetAccess = 'protected')
        Cd;
    end
    
    methods
        function b = seriesElementAE(varargin)
            b@lfpBattery.seriesElement(varargin{:})
        end
        function c = get.Cd(b)
            c = mean([b.El.Cd]);
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
    end
    
end

