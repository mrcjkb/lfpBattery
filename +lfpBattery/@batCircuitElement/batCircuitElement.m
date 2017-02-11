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
            b.findImaxD;
        end
        function charge(b, Q)
            for i = uint32(1):b.nEl
                b.El(i).charge(Q)
            end
        end
        function c = dummyCharge(b, Q)
            c = zeros(b.nEl, 1);
            for i = uint32(1):b.nEl
                c(i) = b.El(i).dummyCharge(Q);
            end
        end
        function i = findImaxD(b)
            i = zeros(b.nEl, 1);
            for ind = 1:b.nEl
                i(ind) = b.El.findImaxD;
            end
        end
    end
    
%     methods (Access = 'protected')
        % gpuCompatible methods
        % These methods are currently unsupported and may be removed in a
        % future version.
        %{
        function setsubProp(obj, fn, val)
            obj.(fn) = val;
        end
        function val = getsubProp(obj, fn)
            val = obj.(fn);
        end
        %}
%     end
    
    methods (Abstract, Access = 'protected')
        p = getZProportions(b); % get proportions of impedances
    end
    
end

