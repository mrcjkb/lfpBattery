classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Battery cell model.
    
    properties (Access = 'protected');
        dC; % curvefitCollection (dischargeCurves object)
    end
    
    methods
        function b = batteryCell(varargin)
           b@lfpBattery.batteryInterface(varargin{:})
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
        function [P, Cd, V, soc] = iteratePower(b, P, dt)
            I = P ./ b.V; 
            Cd = b.Cd - I .* dt ./ 3600;
            V = b.interp(I, Cd);
            Pit = I .* mean([b.V; V]);
            err = b.lastPr - Pit;
            if abs(err) > b.pTol && b.pct < b.maxIterations
                b.pct = b.pct + 1;
                [P, Cd, V, soc] = b.iteratePower(P + err, dt);
            elseif abs(I) > b.Imax + b.iTol % Limit power according to max current using recursion
                b.pct = 0;
                P = sign(I) .* b.Imax .* mean([b.V; V]);
                b.lastPr = P;
                [P, Cd, V, soc] = b.iteratePower(P, dt);
            end
            b.pct = 0;
            if P ~= 0 % Limit power according to SoC using recursion
                soc = 1 - Cd ./ b.Cn;
                os = soc - b.soc; % charged
                req = b.socLim - b.soc; % required to reach limit
                err = (req - os) ./ os;
                if (b.reH(soc, b.socLim) || b.slTF) && abs(err) > b.sTol ...
                        && b.sct < b.maxIterations 
                    b.sct = b.sct + 1;
                    b.slTF = true; % indicate that SoC limiting is active
                    % correct power request
                    P = b.lastPr + err .* b.lastPr;
                    b.lastPr = P;
                    [P, Cd, V, soc] = b.iteratePower(P, dt);
                else
                    b.sct = 0;
                    b.slTF = false;
                end
            end
        end % iteratePower
        %% Methods handled by strategy objects
        function v = interp(b, I, C)
            v = b.dC.interp(I, C);
        end
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
    end
end

