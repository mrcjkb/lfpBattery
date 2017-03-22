classdef commons
    %COMMONS: Class for commonly used static functions.
    %The methods in this class are shared by the classes of the lfpBattery
    %package.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         March 2017
    
    methods (Static)
        function p = getRoot
            % GETROOT: Returns the root path of the lfpBattery package
            [p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
        end
        function javaGUIchk
            % JAVAGUICHK: Throws an error if java.awt or java.swing are not found.
            if ~usejava('awt')
                error('java.awt is required to run this tool.')
            elseif ~usejava('swing')
                error('javax.swing is required to run this tool.')
            end
        end
        function warnHandleSave(obj)
            % WARNHANDLESAVE: Prints a warning to the command window that obj contains
            % handle links that cannot be maintained
            type = class(obj);
            warning(['Saved object of type ', type, ' contains handle links that cannot be maintained when saving to a MAT file. ', ...
                'This may result in unexpected behaviour of the loaded object or in large amounts of data and memory leaks. ', ...
                'It is recommended to initialize the object at runtime.'])
        end
        function onezeroChk(var, varName)
            % ONEZEROCHK: Returns an error if the variable var with varName
            % is not in the interval [0,..1]
            if lfpBattery.commons.ge1le0(var)
                error([varName, ' must be between 0 and 1'])
            end
        end
        function tf = ge1le0(var)
            %GE1LE0: Returns true if var is greater than one or less than
            %zero.
            tf = var > 1 || var < 0;
        end
        function validateInterface(obj, name)
            % VALIDATEINTERFACE: Checks the superclasses to make sure the class obj subclasses
            % the superclass name
            if ~lfpBattery.commons.itfcmp(obj, name)
                error('Specified object does not implement the correct interface.')
            end
        end
        function tf = itfcmp(obj, name)
            % ITFCMP: Compares the class of obj to the name and returns
            % true if obj implements the interface specified by name.
            tf = any(ismember(superclasses(obj), name));
        end
        function y = upperlowerlim(y, low, high)
            % UPPERLOWERLIM: Limits y to interval [low, high]
            y = min(max(low, y), high);
        end
        function x = zeros(chk, varargin)
            % ZEROS: Overloads the builtin ZEROS() function in order to
            % make the lfpBattery package compatible with gpuArrays.
            % Use this function just like the builtin ZEROS function, but
            % place a variable that is a gpuArray if run on a CUDA-enabled
            % GPU as the first argument.
            %
            % Syntax: x = ZEROS(chk);
            %         x = ZEROS(chk, n);
            %         x = ZEROS(chk, sz1,...,szN);
            %         x = ZEROS(chk, sz);
            %
            %         x = ZEROS(__, typename);
            %         x = ZEROS(__,'like', p);
            %
            % Input arguments:
            %
            %   chk: Variable to check for being a gpuArray.
            %
            % SEE ALSO: zeros
            if isa(chk, 'gpuArray')
                x = gpuArray.zeros(varargin{:});
            else
                x = zeros(varargin{:});
            end
        end
        function x = ones(chk, varargin)
            % ONES: Overloads the builtin ONES() function in order to
            % make the lfpBattery package compatible with gpuArrays.
            % Use this function just like the builtin ONES function, but
            % place a variable that is a gpuArray if run on a CUDA-enabled
            % GPU as the first argument.
            %
            % Syntax: x = ONES(chk);
            %         x = ONES(chk, n);
            %         x = ONES(chk, sz1,...,szN);
            %         x = ONES(chk, sz);
            %
            %         x = ONES(chk, classname);
            %         x = ONES(chk, n, classname);
            %
            % Input arguments:
            %
            %   chk: Variable to check for being a gpuArray.
            %
            % SEE ALSO: ones
            if isa(chk, 'gpuArray')
                x = gpuArray.ones(varargin{:});
            else
                x = ones(varargin{:});
            end
        end
        function x = nan(chk, varargin)
            % NAN: Overloads the builtin NAN() function in order to
            % make the lfpBattery package compatible with gpuArrays.
            % Use this function just like the builtin NAN function, but
            % place a variable that is a gpuArray if run on a CUDA-enabled
            % GPU as the first argument.
            %
            % Syntax: x = NAN(chk);
            %         x = NAN(chk, n);
            %         x = NAN(chk, sz1,...,szN);
            %         x = NAN(chk, sz);
            %
            %         x = NAN(chk, classname);
            %         x = NAN(chk, n, classname);
            %
            % Input arguments:
            %
            %   chk: Variable to check for being a gpuArray.
            %
            % SEE ALSO: nan
            if isa(chk, 'gpuArray')
                x = gpuArray.nan(varargin{:});
            else
                x = nan(varargin{:});
            end
        end
        function x = rand(chk, varargin)
            % RAND: Overloads the builtin RAND() function in order to
            % make the lfpBattery package compatible with gpuArrays.
            % Use this function just like the builtin RAND function, but
            % place a variable that is a gpuArray if run on a CUDA-enabled
            % GPU as the first argument.
            %
            % Syntax: x = RAND(chk);
            %         x = RAND(chk, n);
            %         x = RAND(chk, sz1,...,szN);
            %         x = RAND(chk, sz);
            %
            %         x = RAND(__, typename);
            %         x = RAND(__,'like', p);
            %
            % Input arguments:
            %
            %   chk: Variable to check for being a gpuArray.
            %
            % SEE ALSO: rand
            if isa(chk, 'gpuArray')
                x = gpuArray.rand(varargin{:});
            else
                x = rand(varargin{:});
            end
        end
        function [x, varargout] = norminvlim(P, mu, sigma, I, varargin)
            %NORMINVLIM: Computes the inverse normal cumulative distribution function
            %with an approximate mean mu and a standard deviation sigma at the
            %corresponding probabilities in P. The output x is limited to the interval I.
            %This function can also be used to generate random normal distributions with the dimensions dim.
            %
            %Due to the fact that the Gauss distribution is only defined for I = [-inf, inf],
            %the standard deviation and mean can deviate from what is set by the function.
            %This function can be used to attempt to force a standard deviation and/or mean of the limited
            %output as close as possible to the preset one by varying the preset until
            %a match is found.
            %NOTE: Doing this can result in very long computation times. It is often
            %sufficient to either force mu or sigma to reduce the computation times. It
            %is not recommended to force mu or sigma for small data sets and the "force"
            %option is meant for use when randomly generating data.
            %
            %Syntax:  x = norminvlim(P, mu, sigma, I);
            %               --> attempts to limit x to interval I once.
            %
            %         x = norminvlim(dim, mu, sigma, I);
            %               --> generating random probabilities of dimensions dim.
            %
            %         x = norminvlim(FCN, mu, sigma, I);
            %               --> evalueates a function specified by FCN to generate P.
            %
            %         [x, dif] = norminvlim(P, mu, sigma, I);
            %         [x, dif] = norminvlim(dim, mu, sigma, I);
            %         [x, dif] = norminvlim(FCN, mu, sigma, I);
            %               --> outputs dfference between preset sigma and std(x)
            %
            %         norminvlim(dim, mu, sigma, I, 'OptionName', 'OptionValue');
            %         norminvlim(FCN, mu, sigma, I, 'OptionName', 'OptionValue');
            %         norminvlim(P, mu, sigma, I, 'OptionName', 'OptionValue'); (NOT RECOMMENDED)
            %               --> with additional options.
            %
            %         [x, xlo, xup] = norminv(P, mu, sigma, I, pcov, alpha);
            %               --> produces confidence bounds for X when the input parameters mu and sigma are estimates.
            %
            %         [x, dif, xlo, xup] = norminv(P, mu, sigma, I, pcov, alpha);
            %         [x, xlo, xup] = norminv(FCN, mu, sigma, I, pcov, alpha, 'OptionName', 'OptionValue');
            %         [x, dsigma, xlo, xup] = norminv(FCN, mu, sigma, I, pcov, alpha, 'OptionName', 'OptionValue');
            %
            %
            %Input arguments:
            %
            %         P:        Corresponding probabilities (between 0 and 1)
            %         dim:      Dimensions of randomly generated probability matrix
            %                   [rows, columns]
            %         FCN:      1x2 cell array with
            %                   FCN{1} = function handle used to calculate P
            %                   FCN{2} = cell array with the arguments for the function handle in FCN{1}
            %         mu:       Mean of x
            %         sigma:    Standard deviation of x
            %         I:        Interval boundaries [xmin, xmax] (set xmin to -inf or
            %                   xmax to inf if a boundary is not required)
            %         pcov:     (optional) covariance matrix of the estimated parameters
            %         alpha:    (optional) specifies 100(1 - alpha)% confidence bounds
            %
            %Option-Value-Pairs:
            %
            %         - 'ForceSigma':
            %                         (true)    force sigma to deviate only slightly from what is preset.
            %                         (false)   do not force sigma (default)
            %         - 'ForceMu':
            %                         (true)    force mu to deviate only slightly from what is preset.
            %                         (false)   do not force mu (default)
            %         - 'SigmaInc'
            %                         (numeric) If 'ForceSigma' is set to true: Step size with which to
            %                                   increment sigma with each iteration.
            %                                   Increasing this could speed up computation times, but will make it
            %                                   less likely to find a result.
            %                                   Default: sigma./200
            %         - 'MuInc'
            %                         (numeric) If 'ForceMu' is set to true: Step size with which to
            %                                   increment mu with each iteration.
            %                                   Increasing this could speed up computation times, but will make it
            %                                   less likely to find a result.
            %                                   Default: mu./200
            %         - 'MaxSigmaDeviation'
            %                         (numeric) Maximum tolerated deviation of sigma from preset (absolute value) at
            %                                   which to end the iteration (if 'ForceSigma' is set to true)
            %                                   Default: sigma.*2e-3
            %                                   Increasing this value will speed up computation times.
            %         - 'MaxMuDeviation'
            %                         (numeric) Maximum tolerated deviation of mu from preset (absolute value) at
            %                                   which to end the iteration (if 'ForceMu' is set to true)
            %                                   Default: sigma.*2e-3
            %                                   Increasing this value will speed up computation times.
            %
            %Output arguments:
            %
            %         x:        Inverse of the normal cdf
            %         dif:      (optional) differences between std(x) and sigma & mean(x) and mu
            %                              [dif_sigma, dif_mu]
            %         xlo:      (optional) lower confidence bound
            %         xup:      (optional) upper confidence bound
            %
            %
            %Usage examples:
            %         P = rand(50000, 1); %random probabilities (50000x1 vector)
            %         mu = 5000; % set mean to 5000
            %         sigma = 1500; % set standard deviation to 1500
            %         I = [1000, 9000]; % limit output x to [1000, 9000]
            %
            %         % compute x with mu approx. 5000 & sigma apporx 1500:
            %         [x, dif] = norminvlim(P, mu, sigma, I);
            %           --> dif = [48.8841  -5.1145]
            %
            %         dim = [50000, 1]; % Force output using random probabilities
            %         % compute x with mu approx 5000 & sigma == (1500 +- 0.75)
            %         [x, dif] = norminvlim(dim, mu, sigma, I, 'ForceSigma', true);
            %           --> dif = [0.6469   -5.8293]
            %         % compute x with sigma approx 1500 and mu == (5000 +- 2.5)
            %         [x, dif] = norminvlim(dim, mu, sigma, I, 'ForceMu', true);
            %           --> dif = [48.8890    0.7550]
            %
            %Required toolboxes:
            %
            %   Statistics and Machine Learning Toolbox
            %
            %SEE ALSO: NORMINV, NORMCDF, ICDF, NORMFIT, NORMLIKE, NORMPDF, NORMRND, NORMSTAT
            %
            %Author: Marc Jakobi 27.07.2015
            
            
            %% parse inputs
            p = inputParser;
            addOptional(p, 'ForceSigma', false, @(x) islogical(x));
            addOptional(p, 'ForceMu', false, @(x) islogical(x));
            addOptional(p, 'SigmaInc', sigma./200, @(x) isnumeric(x));
            addOptional(p, 'MuInc', mu./200, @(x) isnumeric(x));
            addOptional(p, 'MaxSigmaDeviation', sigma./2e3, @(x) isnumeric(x));
            addOptional(p, 'MaxMuDeviation', mu./2e3, @(x) isnumeric(x));
            if nargout == 3 || nargout == 4 % confidence bounds?
                conf = true;
                pcov = varargin{1};
                alpha = varargin{2};
                varargin = varargin(3:end); % remove pcov & alpha from varargin
            else % normal syntax
                conf = false;
            end
            parse(p, varargin{:})
            SigmaInc = p.Results.SigmaInc;
            MuInc = p.Results.MuInc;
            %% initialize
            if p.Results.ForceSigma
                sigma2 = sigma./2; % initial sigma (limiting output changes sigma from what is preset by user)
            else
                sigma2 = sigma; % this will result in approximate sigma
            end
            if p.Results.ForceMu
                mu2 = mu./2; % initial mu (limiting output changes mu from what is preset by user)
            else
                mu2 = mu; % this will result in approximate mu
            end
            if isequal(size(P), [1, 2]) % generate random probabilities?
                if ~iscell(P)
                    random = true;
                    fhandle = false;
                    dim = P;
                else
                    fcn = P{1};
                    args = P{2};
                    fhandle = true;
                end
            else
                random = false;
                fhandle = false;
                if p.Results.ForceSigma || p.Results.ForceMu
                    warning('Forcing results on non-randomized probablitities is not recommended and can result in extremely long or infinite computation times.')
                end
            end
            if size(mu,2) > 1 % use on matrix?
                mat = true;
                mu = repmat(mu,size(P,1),1);
                sigma2 = repmat(sigma2,size(P,1),1);
                I = repmat(I,size(P,1),1);
            else % use on vector
                mat = false;
            end
            %% norminv loop
            doMu = true;
            while doMu
                doSigma = true;
                while doSigma % This loop will only run once if 'Force' is set to false
                    if random % generate random probabilities
                        P = rand(dim);
                    elseif fhandle % evaluate function specified in FCN input
                        P = feval(fcn, args{:});
                    end
                    if mat % use on  matrix
                        % normal cdf of interval boundaries
                        P1 = normcdf(I(1,:), mu2, sigma2);
                        P2 = normcdf(I(2,:), mu2, sigma2);
                        if conf % confidence bounds
                            % bsxfun is optimized for gpuArrays
                            [x, xlo, xup] = norminv(bsxfun(@plus,bsxfun(@times,P,(P2 - P1)),P1), mu2, sigma2, pcov, alpha);
                        else % normal syntax
                            x = norminv(bsxfun(@plus,bsxfun(@times,P,(P2 - P1)),P1), mu2, sigma2);
                        end
                    else % use on vector
                        P1 = normcdf(I(1), mu2, sigma2);
                        P2 = normcdf(I(2), mu2, sigma2);
                        if conf
                            [x, xlo, xup] = norminv(P1 + (P2 - P1).*P, mu2, sigma2, pcov, alpha);
                        else
                            x = norminv(P1 + (P2 - P1).*P, mu2, sigma2);
                        end
                    end
                    ds = abs(diff([std(x(:)), sigma])) <= p.Results.MaxSigmaDeviation;
                    dm = abs(diff([mean(x(:)), mu])) <= p.Results.MaxMuDeviation;
                    % Conditions for breaking out of loops:
                    % if 'ForceMu' is set to false and std is close enough to preset std.
                    cond1 = ds  &&  ~p.Results.ForceMu;
                    % if 'ForceSigma' is set to false and mean is close enough to preset mean.
                    cond2 = dm  && ~p.Results.ForceSigma;
                    % if mu and sigma are both close enough to presets
                    cond3 = ds && dm;
                    % if both 'ForceMu' and 'ForceSigma' are set to false
                    cond4 = ~p.Results.ForceSigma && ~p.Results.ForceMu;
                    if any([cond1; cond2; cond3; cond4])
                        doSigma = false;
                        doMu = false;
                    end
                    if p.Results.ForceSigma % increment sigma
                        sigma2 = sigma2 + SigmaInc;
                    end
                    if any(sigma2 > 2*sigma)
                        % reset sigma2, increment mu and break out of mu loop
                        sigma2 = sigma./2;
                        doSigma = false;
                    end
                    if ~p.Results.ForceSigma || ds % break out of sigma loop
                        doSigma = false;
                        sigma2 = sigma./2; % reset sigma for next mu iteration
                    end
                end % sigma loop
                if p.Results.ForceMu %increment mu
                    mu2 = mu2 + MuInc;
                end
                if any(mu2 > 2*mu) % nothing found --> Reset mu and decrease increment.
                    mu2 = mu./2;
                    MuInc = MuInc./2;
                end
                if any(sigma2 > 2*sigma) % nothing found --> Reset sigma and decrease increment.
                    sigma2 = sigma./2;
                    SigmaInc = SigmaInc./2;
                end
            end % mu loop
            % differences std & mean from presets
            dif = [diff([std(x(:)), sigma]), diff([mean(x(:)), mu])];
            %% assign outputs
            if nargout == 2
                varargout{1} = dif;
            elseif nargout == 3
                varargout{1} = xlo;
                varargout{2} = xup;
            elseif nargout == 4
                varargout{1} = dif;
                varargout{2} = xlo;
                varargout{3} = xup;
            end
        end % norminvlim
        function str = getHtmlImage(resource, varargin)
            % GETHTMLIMAGE: Retrieves the HTML string for an image.
            % Used by the GUI tools of this package.
            % Syntax: str = getHtmlImage(resource, 'OptionName', 'OptionValue');
            %
            % e. g. str = getHtmlImage('image.png', 'height', '100', ...
            %           'width', '100');
            p = inputParser;
            addOptional(p, 'height', 'auto')
            addOptional(p, 'width', 'auto')
            parse(p, varargin{:})
            h = p.Results.height;
            w = p.Results.width;
            [path, ~] = fileparts(fileparts(which('lfpBatteryTests')));
            path = fullfile(path, 'Resources', resource);
            path = strrep(['file:/', path], '\', '/');
            if nargin < 2
                str = ['<html><img src="', path, '"><br>'];
            else
                if ~strcmp(h, 'auto') && ~strcmp(w, 'auto')
                    str = ['<html><img src="', path, '"', ...
                        'height = "', h, '"', ...
                        'width = "', w, '"><br>'];
                elseif ~strcmp(h, 'auto')
                    str = ['<html><img src="', path, '"', ...
                        'height = "', h, '"><br>'];
                else
                    str = ['<html><img src="', path, '"', ...
                        'width = "', w, '"><br>'];
                end
            end
        end % getHtmlImage
        function redComponent(jb)
            % REDCOMPONENT: colors a java component TU red
            import lfpBattery.* java.awt.*
            jb.setOpaque(true);
            col = const.logo .* 255;
            jb.setBackground(Color(int32(col(1)), int32(col(2)), int32(col(3))));
            jb.setContentAreaFilled(false)
            jb.setForeground(Color.WHITE);
            jb.setBorderPainted(false);
        end
        function [pathname, filename] = uigetimage(title, defPath)
            %UIGETIMAGE: Open file dialog box with preview for bitmap images.
            %
            %Syntax:
            %   fullpath = UIGETIMAGE(title);
            %   fullpath = UIGETIMAGE(title, defPath);
            %   [pathname, filename] = UIGETIMAGE(title);
            %   [pathname, filename] = UIGETIMAGE(title, defPath);
            %
            %Input arguments (optional):
            %
            %   title       - string containing the title of the dialog box.
            %                 (default: 'Select file')
            %   defPath     - string containing the default folder
            %                 (default: pwd)
            %
            %Output arguments:
            %
            %   fullpath    - string containing the name and the path of the
            %                 file selected. If the user presses Cancel, it is
            %                 set to 0.
            %   pathname    - string containing the path of the file selected
            %                 in the dialog box.  If the user presses Cancel,
            %                 it is set to 0.
            %   filename    - string containing the name of the file selected
            %                 in the dialog box. If the user presses Cancel,
            %                 it is set to 0.
            %
            %SEE ALSO: uigetfile
            %
            %Author: Marc Jakobi, February 2017
            %This function uses modified code from Yair Altman's uigetfile_with_preview
            %https://de.mathworks.com/matlabcentral/fileexchange/60074-uigetfile-with-preview-gui-dialog-window-with-a-preview-panel
            import javax.swing.* com.mathworks.mwswing.*
            if nargin < 1
                title = 'Select file';
            end
            if nargin < 2
                defPath = pwd;
            end
            % Prepare dialog box
            d = dialog('Name', title, 'Visible', 'off');
            % d.Units = 'normalized';
            % d.Position = [0.3170    0.0938    0.3660    0.7813];
            d.Position = [0, 0, 700, 650];
            movegui(d, 'center')
            d.Visible = 'on';
            % Add JFileChooser object
            jfc = JFileChooser;
            hjfc = javacomponent(jfc, [0, 300, 700, 350], d);
            hjfc.setCurrentDirectory(java.io.File(defPath));
            drawnow;
            % Add file types
            filterSpec = {'All supported file types (*.jpg,*.tif,*.tiff,*.gif,*.png,*.bmp)', ...
                {'jpg'; 'tif'; 'tiff'; 'gif'; 'png'; 'bmp'}; ...
                'JPEG files (*.jpg,*.jpeg)', ...
                {'jpg'; 'jpeg'}; ...
                'TIFF filles (*.tif,*.tiff)', ...
                {'tif'; 'tiff'}; ...
                'GIF files (*.gif)', ...
                {'gif'}; ...
                'PNG files (*.png)', ...
                {'png'}; ...
                'Bitmap files (*.bmp)', ...
                {'bmp'}};
            hjfc.setAcceptAllFileFilterUsed(false);
            for i = 1:size(filterSpec, 1)
                ext = regexprep(filterSpec{i, 2} ,'^.*\*?\.','');
                extFilter = FileExtensionFilter(filterSpec{i, 1}, ext, false, true);
                javaMethodEDT('addChoosableFileFilter', hjfc, extFilter);
            end
            % Prepare the preview panel
            hprev = uipanel('parent', d, 'title', 'Preview', 'units', 'pixel', ...
                'Position', [10, 10, 680, 280]);
            % % ax = axes('Parent', hprev, 'units', 'norm', 'LooseInset', [0 0 0 0]);
            % ax.YTick = [];
            % ax.XTick = [];
            % ax.Box = 'off';
            % Prepare the figure callbacks
            hjfc.PropertyChangeCallback  = {@lfpBattery.commons.PreviewCallback, hprev};
            hjfc.ActionPerformedCallback = {@lfpBattery.commons.ActionPerformedCallback, d};
            % Key-typed callback
            try
                hFn = handle(hjfc.getComponent(2).getComponent(2).getComponent(2).getComponent(1), 'CallbackProperties');
                hFn.KeyTypedCallback = {@KeyTypedCallback, hjfc};
            catch
                % maybe the file-chooser editbox changed location
            end
            uiwait(d);
            % We get here if the figure is either deleted or Cancel/Open were pressed
            if ishghandle(d)
                % Open were clicked
                pathname = getappdata(d, 'selectedFile');
                close(d);
                if nargout > 1
                    [pathname, filename, ext] = fileparts(pathname);
                    filename = [filename, ext];
                end
            else  % figure was deleted/closed
                pathname = 0;
                if nargout > 1
                    filename = 0;
                end
            end
        end  % uigetimage
        
        function PreviewCallback(hjfc, ~, hprev)
            % PREVIEWCALLBACK: Preview callback function for uigetimage
            % class
            persistent nameCache;
            persistent imCache;
            persistent cIdx;
            if isempty(nameCache)
                nameCache = cell(100, 1);
                imCache = nameCache;
                cIdx = 0;
            end
            try
                % Get the selected file
                filename = char(hjfc.getSelectedFile);
                if isempty(filename) || ~exist(filename,'file')
                    return;  % bail out
                end
                hObjs = findall(hprev);
                hObjs = setdiff(hObjs, findall(hprev, 'string', get(hprev,'title')));  % keep the title
                hObjs = setdiff(hObjs, hprev);
                delete(hObjs);
                ax = axes('Parent', hprev, 'units', 'norm', 'LooseInset', [0 0 0 0]);
                tf = ismember(nameCache(1:cIdx), filename);
                if any(tf)
                    im = imCache{tf};
                else
                    im = imread(filename);
                    cIdx = cIdx + 1;
                    if cIdx > 100
                        cIdx = 1;
                    end
                    imCache{cIdx} = im;
                    nameCache{cIdx} = filename;
                end
                imshow(im, 'Parent', ax, 'InitialMagnification', 'fit');
            catch ME
                warning(ME.message)
                % Never mind - bail out...
            end
        end  % PreviewCallback
        
        function ActionPerformedCallback(hjfc, eventData, d)
            % Callback for uigetimage
            switch char(eventData.getActionCommand)
                case 'CancelSelection'
                    close(d);
                case 'ApproveSelection'
                    files = cellfun(@char, cell(hjfc.getSelectedFiles), 'uniform', 0);
                    if isempty(files)
                        files = char(hjfc.getSelectedFile);
                    end
                    setappdata(d,'selectedFile', files);
                    uiresume(d);
            end
        end  % ActionPerformedCallback
        % Key-types callback in the file-name editbox
        function KeyTypedCallback(hEditbox, ~, hjFileChooser)
            text = char(get(hEditbox, 'Text'));
            [wasFound, ~, ~, folder] = regexp(text,'(.*[:\\/])');
            if wasFound
                % This will silently fail if folder does not exist
                hjFileChooser.setCurrentDirectory(java.io.File(folder));
            end
        end
    end % methods
end

