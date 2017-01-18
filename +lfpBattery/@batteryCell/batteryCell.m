classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Battery cell model.
    
    properties (Access = 'protected');
        dC; % curvefitCollection (dischargeCurves object)
        Vi; % for storing V property of batteryInterface
        Cdi; % for storing Cd property of batteryInterface
    end
    
    methods
        function b = batteryCell(Cn, Vn, varargin)
           b@lfpBattery.batteryInterface('Cn', Cn, 'Vn', Vn, varargin{:})
        end
        function P = powerRequest(b, P, dt)
            
            % set operator handles according to charge or discharge
            if P > 0 % charge
                P = b.eta_bc .* P; % limit by charging efficiency
                b.reH = @gt; % greater than
                b.socLim = b.socMax;
            else % discharge
                if P == 0 % Set P to self-discharge power and limit soc to zero
                    b.socLim = eps; % eps in case dambrowskiCounter is used for cycle counting
                    P = b.Psd;
                else
                    P = b.eta_bd .* P; % limit by discharging efficiency
                    b.socLim = b.socMin;
                end
                b.reH = @lt; % less than
            end
            if abs(b.socLim - b.soc) > b.sTol
                b.lastPr = P;
                [P, b.Cd, b.V, b.soc] = b.iteratePower(P, dt);
            else
                P = 0;
            end
        end % powerRequest
        function [v, cd] = getNewState(b, I, dt)
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
    end
    
    methods (Access = 'protected')
        function findImax(b)
            if ~isempty(b.dC)
                b.Imax = max(b.dC.z);
            else
                b.Imax = 0;
            end
        end
        %% Implementation of abstract setters
        function setV(b, v)
            b.Vi = v;
        end
        function setCd(b, c)
            b.Cdi = c;
        end
        %% Implementation of abstract getters
        function v = getV(b)
            v = b.Vi;
        end
        function c = getCd(b)
            c = b.Cdi;
        end
    end
end

