classdef (Abstract) batteryAgeModel < handle % MTODO: make abstract
    %BATTERYAGEMODEL Abstract class for modelling the aging of a battery.
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners for the SohChanged and EolReached events.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    
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
        function b = batteryAgeModel(eols, init_soh)
            %BATTERYAGEMODEL Constructor:
            %
            %   b = batteryAgeModel;                creates a batteryAgeModel object
            %                                       with an end of life SoH of 0.2
            %   b = batteryAgeModel(eol);           creates a batteryAgeModel object
            %                                       with an end of life SoH
            %                                       specified by eol
            %   b = batteryAgeModel(eol, init_soh); initializes the SoH
            %                                       with init_soh
            if nargin < 1
                eols = 0.2;
                init_soh = 1;
            elseif nargin < 2
                init_soh = 1;
            end
            lfpBattery.errChks.onezeroChk(eols, 'eol')
            lfpBattery.errChks.onezeroChk(init_soh, 'init_soh')
            b.eolSoH = eols;
            b.SoH = init_soh;
        end
        % Dependent setters
        function set.Ac(b, a)
            b.Ac = a;
            notify(b, 'SohChanged')
            if b.Ac >= b.eolAc %#ok<MCSUP>
                notify(b, 'EolReached')
            end
        end
        function set.SoH(b, soh)
           b.Ac = 1-soh; 
        end
        function set.eolSoH(b, soh)
            lfpBattery.errChks.onezeroChk(soh, 'End of life state of health')
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

