classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Battery cell model.
    
    properties (Access = 'protected');
        dC; % curvefitCollection (dischargeCurves object)
    end
    
    methods
        function P = powerRequest(b, P, dt)
            % P:  power in W
            % dt: size of time step in S
            
            % set operator handles according to charge or discharge
            if P > 0 % charge
                pmH = @plus;
                reH = @gt; % greater than
                socLim = b.socMax;
                sd = false; % self-discharge
            else % discharge
                if P == 0 % MTODO: calculate self-discharge
                    sd = true;
                else
                    sd = false;
                end
                pmH = @minus;
                reH = @lt; % less than
                socLim = b.socMin;
            end
            P = b.iteratePower(P, dt, pmH, reH, socLim, sd);
            % MTODO: notify neighbours about new capacity here and pass dt
        end
        %% Methods handled by strategy objects
        function v = interp(b, I, C)
            v = b.dC.interp(I, C);
        end
        function adddfit(b, d)
            if isempty(b.dC) % initialize
                b.dC = lfpBattery.dischargeCurves;
            end
            b.dC.add(d);
        end
        function adddcurves(b, d)
            if isempty(b.dC) % initialize dC property with d
                b.dC = d;
            else % add d if dC exists already
                b.dC.add(d)
            end
        end
    end
    
    methods (Access = 'protected')
        function P = iteratePower(b, P, dt, pmH, reH, socLim, sd)
            %ITERATEPOWER: Iteration to determine current and new state using recursion
            I = P ./ b.V; % MTODO: Limit I according to data sheet
            Cd = b.Cd - I .* dt ./ 3600;
            V = b.interp(I, Cd);
            Pit = I .* mean([b.V; V]);
            err = P - Pit;
            if abs(err) > b.pTol && b.pct < b.maxIterations
                b.pct = b.pct + 1;
                b.iteratePower(P + err, dt, pmH, reH, socLim, sd);
            elseif P ~= 0
                b.pct = 0;
                % Limit power here using recursion
                soc = 1 - Cd ./ b.Cn;
                ous = socLim - soc; % over-/under shot
                req = socLim - b.soc; % required to reach limit
                if (reH(soc, socLim) || b.slTF) && abs(ous) > b.sTol ...
                        && b.sct < b.maxIterations && ~sd
                    b.sct = b.sct + 1;
                    b.slTF = true; % indicate that SoC limiting is active
                    % correct power request
                    P = b.iteratePower(pmH(P, P.*req./abs(ous)), dt, pmH, reH, socLim, sd);
                    % BUG: Attempting to exceed limit once limit is set results
                    % in long iteration
                else
                    b.sct = 0;
                    b.slTF = false;
                    b.Cd = Cd;
                    b.V = V;
                    b.soc = soc;
                end
            end
        end
    end
end

