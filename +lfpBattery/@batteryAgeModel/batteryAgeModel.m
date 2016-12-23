classdef (Abstract) batteryAgeModel < handle % MTODO: make abstract
    %BATTERYAGEMODEL Abstract class for modelling the aging of a battery.
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners.
    
    properties (Hidden, SetAccess = 'protected')
        Ac; % Total age loss [0..1]
        eolAc; % age at which end of life is reached 
    end
    properties (Dependent)
        SoH; % State of health [0..1]
        eolSoH; % SoH at which end of life is reached.
    end

    events
        SohChanged; % Notify listeners that the state of health has changed
        EolReached; % Notify listeners that the end of life specified by eolSoH has been reached
    end
    methods
        % Constructor
        function b = batteryAgeModel(eols)
            if nargin < 1
                eols = 0.2;
            end
            b.eolSoH = eols;
        end
        % Dependent setters
        function set.Ac(b, a)
            b.Ac = a;
            notify(b, 'SohChanged')
            if b.Ah >= b.eolAh
                notify(b, 'EolReached')
            end
        end
        function set.eolSoH(b, soh)
            if soh > 1 || soh < 0
                error('End of life state of health must be a value between 0 and 1')
            end
            b.eolAc = 1 - soh;
        end
        % Dependent getters
        function soh = get.SoH(b)
            soh = 1 - b.Ac;
        end
        function soh = get.eolSoH(b)
            soh = 1 - b.eolAh;
        end
    end
    methods (Abstract, Access = 'protected')
        b = addAging(b); % add to the age.
    end
end

