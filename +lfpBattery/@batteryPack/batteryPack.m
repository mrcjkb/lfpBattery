classdef batteryPack < lfpBattery.batteryInterface & lfpBattery.composite
    %BATTERYPACK: Model of lithium iron phosphate battery pack containing
    %multiple cells
    
    properties (SetAccess = 'immutable')
        ageModelLevel = 'pack'; % 'pack' or 'cell'
    end
    properties (Access = 'protected')
        cells; % batteryCell objects % MTODO: create classes for different topologies (PS, SP,...)
    end
    
    methods
        function b = batteryPack(varargin)
            b@lfpBattery.batteryInterface(varargin{:})
        end
%         function powerRequest(b, P, dt)
            % MTODO: implement charging function here
%         end
%         function adddfit(b, d)
            % MTODO: add discharge fit handle to cells
%             b.findImax();
%         end
%         function adddcurves(b, d)
            % MTODO: add discharge curve handle to cells
            %b.findImax();
%         end
%         function it = createIterator(b)
%            % MTODO: create iterator class and implement this method
%         end
    end
    
end

