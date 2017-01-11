classdef (Abstract) batteryAgeModel < handle
    %BATTERYAGEMODEL Abstract class for modelling the aging of a battery.
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners for the SoH property and the EolReached event.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    
    properties
        eolSoH; % SoH at which end of life is reached.
    end
    properties (SetObservable, SetAccess = 'private')
        % State of health [0..1] (observable)
        % This property can be observed by adding an event listener
        % to a batteryAgeModel subclass with this classe's addlistener() method:
        %       addlistener(b, 'SoH', 'PostSet', @obj.handlePropertyEvents);
        % Subcalsses cannot set this property and should set the Age (Ac
        % property instead)
        SoH;
    end
    properties (Dependent, SetAccess = 'protected')
        Ac; % Total age loss [0..1]
    end
    properties (Dependent)
        eolAc; % age at which end of life is reached 
    end
    events
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
            lfpBattery.commons.onezeroChk(eols, 'eol')
            lfpBattery.commons.onezeroChk(init_soh, 'init_soh')
            b.eolSoH = eols;
            b.SoH = init_soh;
        end
        % Dependent setters
        function set.Ac(b, a)
            b.SoH = 1-a;
            if b.SoH <= b.eolSoH
               notify(b, 'EolReached')
           end
        end
        function set.eolAc(b, a)
            lfpBattery.commons.onezeroChk(a, 'End of life state of health')
            b.eolSoH = 1 - a;
        end
        % Dependent getters
        function a = get.Ac(b)
            a = 1 - b.SoH;
        end
        function a = get.eolAc(b)
            a = 1 - b.eolSoH;
        end
    end
    methods (Abstract, Access = 'protected')
        b = addAging(b); % add to the current age.
    end
end

