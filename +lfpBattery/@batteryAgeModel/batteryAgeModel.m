classdef (Abstract) batteryAgeModel < handle
    %BATTERYAGEMODEL Abstract class for modelling the aging of a battery.
    %Notifies event listeners (observers) every time the SoH property changes. Use this class's
    %addlistener() method to add event listeners for the SoH property and the EolReached event.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         December 2016
    
    properties
        eolSoH; % SoH at which end of life is reached.
    end
    properties (Hidden, GetAccess = 'protected')
        % cycleCurveFit object or function handle (must implement the curveFitInterface)
        % of a cycles to failure = f(DoC) curve.
        wFit;
    end
    properties (SetObservable, SetAccess = 'private')
        % State of health [0..1] (observable)
        % This property can be observed by creating an event listener
        % for a batteryAgeModel subclass with the class's addlistener() method:
        %       addlistener(b, 'SoH', 'PostSet', @obj.handlePropertyEvents);
        %              - b is the batteryAgeModel subclass (the source)
        %              - @obj.handlePropertyEvents is a handle to the
        %                   object's function that is called when the object is
        %                   notified of the SoH change.
        % Subcalsses cannot set this property and should set the Age (Ac
        % property instead), which is equal to 1-SoH.
        SoH;
    end
    properties (Dependent, SetAccess = 'protected')
        Ac; % Total age loss [0..1] = 1-SoH
    end
    properties (Dependent)
        % Age at which end of life is reached [0..1]
        % e. g. 0.2 for an end of life at an age of 20 %
        % or at an SoH of 80 %, respectively.
        eolAc;
    end
    properties (Access = 'protected')
        lh; % Event listener (observer)
    end
    events
        EolReached; % Notifys listeners (observers) that the end of life specified by eolSoH has been reached
    end
    methods
        function b = batteryAgeModel(cy, eols, init_soh)
            %BATTERYAGEMODEL Constructor:
            %
            %   b = BATTERYAGEMODEL(cy);                creates a batteryAgeModel object
            %                                           with an end of life SoH
            %                                           of 0.2 (20 %)
            %   b = BATTERYAGEMODEL(cy, eol);           creates a batteryAgeModel object
            %                                           with an end of life SoH
            %                                           specified by eol (must
            %                                           be between 0 and 1)
            %   b = BATTERYAGEMODEL(cy, eol, init_soh); initializes the SoH
            %                                           with init_soh (must be
            %                                           between 0 and 1)
            %
            %   cy is a cycleCounter object that is to be observed by b.
            if nargin < 2
                eols = 0.8;
            end
            if nargin < 3
                init_soh = 1;
            end
            if nargin > 0
                b.addCounter(cy)
            end
            % Make sure values are between 0 and 1
            lfpBattery.commons.onezeroChk(eols, 'eol')
            lfpBattery.commons.onezeroChk(init_soh, 'init_soh')
            b.eolSoH = eols;
            b.SoH = init_soh;
        end
        function addCounter(b, cy)
            % Make sure cy is a subclass of cycleCounter and register this class
            % as an observer/listener
            lfpBattery.commons.validateInterface(cy, 'lfpBattery.cycleCounter')
            if ~isempty(b.lh)
                delete(b.lh)
            end
            b.lh = addlistener(cy, 'NewCycle', @b.addAging);
        end
        % setters
        function set.wFit(a, fit)
            if ~isa(fit, 'function_handle')
                lfpBattery.commons.validateInterface(fit, 'lfpBattery.curveFitInterface')
            end
            a.wFit = fit;
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
        % ADDAGING adds to the battery's age every time a cycleCounter
        % object (or subclass) notifies about a new cycle.
        addAging(b, src, ~);
    end
end