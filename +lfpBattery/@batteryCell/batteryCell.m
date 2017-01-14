classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Battery cell model.
    
    properties 
    end
    
    methods
        function powerRequest(b, P, dt)
            % P:  power in W
            % dt: size of time step in S
            % MTODO: Adapt function to C in Ah 
            % MTODO: change dischargeFit unit in plotResults to Ah
            % MTODO: convert Cd to Ah in respective MLunit tests
            % set operator handles according to charge or discharge
            if P > 0 % charge
                pmH = @plus;
            else % discharge
                if P == 0 % MTODO: calculate self-discharge
                    
                end
                pmH = @minus;
            end
            % MTODO: See if possible to use iteration method that
            % converges faster
            I = 0; 
            eps = 1;
            while eps > 1e-3 % MTODO: make tolerance settable property
                I = pmH(I, 0.1); % MTODO: change 0.01 to constant (delta)
                % MTODO: move this part to iterate method
                C = pmH(b.C, I.*dt); % resulting capacity
                V = b.dC(I, C0); % MTODO add dischargeCurves as property
                eps = abs(mean(b.V, V).*I - P);
                % MTODO: Calculate new I according to eps instead of incrementing
            end
            b.V = V;
            b.C = C;
            % MTODO: notify neighbours about new capacity here and pass dt
        end
    end
    
end

