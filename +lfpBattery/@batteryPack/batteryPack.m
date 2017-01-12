classdef batteryPack < lfpBattery.batteryInterface & lfpBattery.composite
    %BATTERYPACK: Model of lithium iron phosphate battery pack containing
    %multiple cells
    
    properties (SetAccess = 'immutable')
        ageModelLevel = 'pack'; % 'pack' or 'cell'
    end
    
    methods
        function b = chargeRequest(b, P)
            % MTODO: implement charging function here
        end
%         function it = createIterator(b)
%            % MTODO: create iterator class and implement this method
%         end
    end
    
end

