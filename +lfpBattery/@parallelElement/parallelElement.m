classdef parallelElement < batteryInterface
    %PARALLELELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = 'protected')
        function v = getV(b)
            v = arrayfun(@mean, b.El.V);
        end
    end
    
end

