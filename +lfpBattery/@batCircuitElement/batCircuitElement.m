classdef (Abstract) batCircuitElement < lfpBattery.batteryInterface
    %BATCIRCUITELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = 'protected')
        iMaxFun;
    end
    
    methods
        function b = batCircuitElement(varargin)
            b@lfpBattery.batteryInterface(varargin{:})
        end
        function addcurves(b, d, type)
            % pass on to all elements
            arrayfun(@(x) addcurves(x, d, type), b.El)
            b.findImax;
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = arrayfun(@(x) findImax(x), b.El);
        end
        function charge(b, Q)
            arrayfun(@(x) charge(x, Q), b.El)
        end
        function c = dummyCharge(b, Q)
            c = arrayfun(@(x) dummyCharge(x, Q), b.El);
        end
    end
    
    methods (Abstract, Access = 'protected')
        p = getZProportions(b); % get proportions of impedances
    end
    
end

