classdef batteryPack < lfpBattery.batteryInterface
    %BATTERYPACK: Model of lithium iron phosphate battery pack containing
    %multiple cells
    
    properties (SetAccess = 'immutable')
        ageModelLevel = 'pack'; % 'pack' or 'cell'
    end
    
    methods
        function b = chargeRequest(b, P)
            % MTODO: implement charging function here
        end
    end
    
end

