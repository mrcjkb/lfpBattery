classdef simpleSEA < lfpBattery.simpleSE
    %SIMPLESEA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        V;
    end

    methods
        function v = get.V(b)
            v = b.nEl .* b.El.V;
        end
        function set.V(b, v)
            % Pass v on to all elements equally to account for balancing
            b.El.V = v ./ b.nE;
        end
    end
    
end

