classdef (Abstract) batteryAgeModel < handle % MTODO: make abstract
    %BATTERYAGEMODEL Abstract class for modelling the aging of a battery.
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners.
    
    properties
        SoH; % State of health [0..1]
    end
    events
        SohChanged; % Notify listeners that the state of health has changed
    end
    methods
        function set.SoH(b, soh)
            b.SoH = soh;
            notify(b, 'SohChanged')
        end
    end
    
end

