classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Battery cell model.
    
    properties (Access = 'protected');
        dC; % curvefitCollection (dischargeCurves object)
        Vi; % for storing dependent V property
        zi; % for storing dependent Zi property
    end
    properties (Dependent)
        V;
    end
    properties (Dependent, SetAccess = 'protected')
        Cd;
    end
    properties (Dependent, SetAccess = 'immutable')
        Zi;
    end
    
    methods
        function b = batteryCell(Cn, Vn, varargin)
            % BATTERYCELL: Initializes a batteryCell object. 
            %
            % Syntax:   BATTERYCELL(Cn, Vn)
            %           BATTERYCELL(Cn, Vn, 'OptionName', 'OptionValue')
            % obj@lfpBattery.batteryInterface('Name', 'Value');
            %
            % Input arguments:
            % Cn            -    nominal capacity in Ah (default: empty)
            % Vn            -    nominal voltage in Ah (default: empty)
            %
            % Name-Value pairs:
            %
            % Zi            -    internal impedance in Ohm (default: 17e-3)
            % sohIni        -    initial state of health [0,..,1] (default: 1)
            % socIni        -    initial state of charge [0,..,1] (default: 0.2)
            % socMin        -    minimum state of charge (default: 0.2)
            % socMax        -    maximum state of charge (default: 1)
            % ageModel      -    'none' (default), 'EO' (for event oriented
            %                    aging) or a custom age model that implements
            %                    the batteryAgeModel interface.
            % cycleCounter  -    'auto' for automatic determination
            %                    depending on the ageModel (none for 'none'
            %                    and dambrowskiCounter for 'EO' or a custom
            %                    cycle counter that implements the
            %                    cycleCounter interface.
            
            b@lfpBattery.batteryInterface(varargin{:})
            %% parse optional inputs
            p = lfpBattery.batteryInterface.parseInputs(varargin{:});
            
            b.Zi = p.Results.Zi;
            b.Cn = Cn;
            b.Cdi = (1 - b.soc) .* b.Cn;
            b.Vn = Vn;
            b.V = b.Vn;
            b.hasCells = true; % always true for batteryCell
        end
        function [P, I] = powerRequest(b, P, dt)
            [P, I] = powerRequest@lfpBattery.batteryInterface(b, P, dt);
            Q = I .* dt ./ 3600; % charged / discharged amount in Ah
            b.charge(Q)
            b.refreshSoC; % re-calculates element-level SoC as a total
        end
        function [v, cd] = getNewVoltage(b, I, dt)
            cd = b.Cd - I .* dt ./ 3600;
            v = b.dC.interp(I, cd);
        end
        function it = createIterator(~)
            it = lfpBattery.nullIterator;
        end
        %% Methods handled by strategy objects
        function addcurves(b, d, type)
            if nargin < 3
                type = 'discharge';
            end
            if strcmp(type, 'discharge')
                if isempty(b.dC) % initialize dC property with d
                    if lfpBattery.commons.itfcmp(d, 'lfpBattery.curvefitCollection')
                        b.dC = d; % init with collection
                    else
                        b.dC = lfpBattery.dischargeCurves; % create new curve fit collection
                        b.dC.add(d)
                    end
                else % add d if dC exists already
                    b.dC.add(d)
                end
            elseif strcmp(type, 'cycleLife')
                b.ageModel.wFit = d; % MTODO: Implement tests for this
            end
            b.findImax();
        end
        %% Getters & setters
        function v = get.V(b)
            v = b.Vi;
        end
        function set.V(b, v)
            b.Vi = v;
        end
        function c = get.Cd(b)
            c = b.Cdi;
        end
        function set.Zi(b, z)
            b.zi = z;
        end
        function z = get.Zi(b)
            z = b.zi;
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            if ~isempty(b.dC)
                b.Imax = max(b.dC.z);
            else
                b.Imax = 0;
            end
            if nargout > 0
                i = b.Imax;
            end
        end
        function refreshNominals(b)   %#ok<MANU> Method not needed
        end
        function charge(b, Q)
            b.Cdi = b.Cdi - Q;
            b.refreshSoC;
        end
        function s = sohCalc(b)
            % sohCalc always points to internal soh for batteryCell
            s = b.soh;
        end
    end
end

