classdef cycleCounter3 < lfpBattery.cycleCounter
    %CYCLECOUNTER3: For counting cycles of multiple SoC profiles at once.
    
    
    %NOTE: If used on a matrix of cells, a column vector indicates cells in series and a row vector indicates 
    properties (Hidden = true, SetAccess = 'immutable', GetAccess = 'protected');
        sz % size of soc matrix
        % NOTE: [r, c] = sub2ind
    end
    methods
        %% constructor
        function c = cycleCounter3(init_soc, soc_max)
            % CYCLECOUNTER constructor
            if nargin == 0
                init_soc = eps;
                soc_max = 1;
            elseif nargin == 1
                soc_max = 1;
            end
            if any(soc_max > 1) || any(soc_max < 0)
                error('soc_max must be between 0 and 1')
            elseif any(init_soc > soc_max)
                error('init_soc must be smaller than soc_max')
            end
            init_soc(init_soc == 0) = eps;
            c.sz = size(init_soc);
            c.currCycle = [init_soc(:), nans(size(init_soc(:)))]; % nan to make sure it is a column vector
            c.soc0 = init_soc(:);
            c.isnewC = false(size(c.soc0));
            c.socMax = soc_max(:);
            c.ct = ones(size(c.soc0), 'int32');
        end % constructor
        %% update method
        function c = update(c, soc)
            %UPDATE: Use this method to add a new SoC value to a
            %cycleCounter3 object c.
            assert(isequal(size(soc), c.sz), 'SoC matrix dimension mismatch')
            soc = soc(:);
            soc(soc == 0) = eps;
            iIdle = soc == c.soc0; % log. indexes of idle states
            c = c.addSoC(soc, iIdle);
            c.isnewC = iIdle && soc == c.socMax; % log. indexes of new cycles
            if any(c.isnewC)
                c = c.dambrowskiCount; % count cycles
            end
            % reset SoC where new cycles occured
            c.currCycle(c.isnewC) = c.currCycle(c.isnewC).*0;
            c.ct(c.isnewC) = int32(1);
            c.currCycle(c.isnewC, ones(sum(c.isnewC), 1)) = soc(c.isnewC);
            c.soc0 = soc;
        end % update
    end % public methods
    
    %% protected methods
    methods (Access = 'protected')
        function c = addSoC(c, soc, iIdle)
            %ADDSOC: increments indexing counters and adds soc to currCycle
            %where soc is not the same as the last value
            c.ct(~iIdle) = c.ct(~iIdle) + 1;
            c.currCycle(~iIdle, c.ct(~iIdle)) = soc(~iIdle);
        end % addSoC
        %% maximum finder
        function imax = iMaxima(c)
            %IMAXIMA: finds the indices of the local maxima in the
            %SoC-profiles
            %Syntax: imax = c.iMaxima;
            %
            %Output:
            %   - imax: Indexes of the local maxima of SoC
            %
            %Relevant code used from extrema
            %https://de.mathworks.com/matlabcentral/fileexchange/12275-extrema-m--extrema2-m
            %
            %NOTE: NaNs are not filtered in this function.
            
            x = c.currCycle(c.isnewC, 1:max(c.ct(c.isnewC)));
            x_sz = fliplr(size(x));
            x = x(:); % MTODO: test out if this works; if not use bsxfun
            Nt = int32(numel(x));
            a = (1:Nt)';
            b = (diff(x) > 0);     %1  =>  positive slope (begin of minima)
            %0  =>  negative slope (begin of maxima)
            xb  = diff(b);          %-1 =>  indices of maxima
            %+1 =>  indices of minima
            imax = a(find(xb == -1) + 1); % indices of maxima
            imin = a(find(xb == 1) + 1); % indices of minima
            nmaxi = numel(imax);
            nmini = numel(imin);
            % Maximum or minumim at the ends? (for initialization)
            if (nmaxi == 0)
                imax = zeros(0, 0, 'int32');
            else
                if imax(1) < imin(1)
                    imin(2:nmini+1) = imin;
                    imin(1) = 1;
                else
                    imax(2:nmaxi+1) = imax;
                    imax(1) = 1;
                end
                if imax(end) <= imin(end)
                    imax(end+1) = Nt;
                end
                [I, J] = ind2sub(x_sz, imax);
                imax = zeros(max(J), max(I), 'int32');
                imax(J,I);
            end
        end % iMaxima
    end % protected methods
    
end

