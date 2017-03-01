classdef ccListener < handle
    %CCLISTENER eventListener class for the purpose of recognizing a
    %cycleCounter object's full cycles in cycleCounterTests
    
    properties
        isnewC = false;
        cDoC;
    end
    
    methods
        function c = ccListener(cy)
            %CCLISTENER: Constructor:
            %   c = ccListener(cy) - creates a listener for the
            %   cycleCounterObject cy
            addlistener(cy, 'NewCycle', @c.setnewC);
        end
        function setnewC(c, src, ~)
            c.isnewC = true;
            c.cDoC = src.cDoC;
        end
    end
    
end

