classdef ccListener < handle
    %CCLISTENER eventListener class for the purpose of recognizing a
    %cycleCounter object's full cycles in cycleCounterTests
    
    properties
        isnewC = false;
    end
    
    methods
        function c = ccListener(cy)
            %CCLISTENER: Constructor:
            %   c = ccListener(cy) - creates a listener for the
            %   cycleCounterObject cy
            addlistener(cy, 'NewCycle', @c.setnewC);
        end
        function c = setnewC(c, ~, ~)
            c.isnewC = true;
        end
    end
    
end

