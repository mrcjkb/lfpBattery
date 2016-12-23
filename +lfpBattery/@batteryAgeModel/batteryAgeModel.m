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
        function b = batteryAgeModel(eols, init_age)
            %BATTERYAGEMODEL Constructor:
            %
            %   b = batteryAgeModel;                creates a batteryAgeModel object
            %                                       with an end of life SoH of 0.2
            %   b = batteryAgeModel(eol);           creates a batteryAgeModel object
            %                                       with an end of life SoH
            %                                       specified by eol
            %   b = batteryAgeModel(eol, init_age); initializes the age
            %                                       with init_age
            if nargin < 1
                eols = 0.2;
                init_age = 0;
            elseif nargin < 2
                init_age = 0;
            end
            errChks.onezeroChk(eols, 'eols')
            errChks.onezeroChk(init_age, 'init_age')
            b.eolSoH = eols;
            b.Ac = init_age;
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
            errChks.onezeroChk(soh, 'End of life state of health')
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

