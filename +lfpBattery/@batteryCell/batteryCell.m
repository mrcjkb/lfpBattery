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
            % MTODO: Move this to batteryInterface?
            % P:  power in W
            % dt: size of time step in S
            
            % set operator handles according to charge or discharge
            if P > 0 % charge
                b.reH = @gt; % greater than
                b.socLim = b.socMax;
            else % discharge
                if P == 0 % MTODO: calculate self-discharge
                    b.socLim = 0;
%                     P = selfDischargePower;
                else
                    b.socLim = b.socMin;
                end
                b.reH = @lt; % less than
            end
            if abs(b.socLim - b.soc) > b.sTol
                b.lastPr = P;
                [P, b.Cd, b.V, b.soc] = b.iteratePower(P, dt);
                % MTODO: handle battery efficiency here.
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
        function adddfit(b, d)
            if isempty(b.dC) % initialize
                b.dC = lfpBattery.dischargeCurves;
            end
            b.dC.add(d);
            b.findImax();
        end
        function adddcurves(b, d)
            if isempty(b.dC) % initialize dC property with d
                b.dC = d;
            else % add d if dC exists already
                b.dC.add(d)
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

