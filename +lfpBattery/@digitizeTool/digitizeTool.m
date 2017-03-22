classdef digitizeTool < handle
    %DIGITIZETOOL: Opens GUI tool for digitizing and fitting curves.
    % Discharge curves (voltage vs. discharge capacity) and cycle life
    % curves (cycles to failure vs. depth of charge) can be digitized from
    % images and fitted for the batteryCell class using this tool.
    %
    % Note: This class uses undocumented JAVA GUI components and requires
    % the java.awt and javax.swing packages. These usually come
    % pre-installed with MATLAB.
    %
    % Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %          January 2017
    %
    %
    % SEE ALSO: lfpBattery.batteryCell lfpBattery.batteryPack
    % lfpBattery.dischargeFit lfpBattery.woehlerFit
    % lfpBattery.dischargeCurves
    properties
        fit;
        ImgData;
    end
    properties (Hidden)
        list;
        externalControl = false;
        sendbutton;
        varname;
        mainframe;
        hInfo;
        errCt; % error counter
    end
    properties (Hidden, Access = 'protected')
        axes1;
        resetbutton;
        plotbutton;
        selectbutton;
        states; % Cell array holding the state objects
        state; % state object that handles the fit methods
    end
    methods
        function obj = digitizeTool(varargin)
            lfpBattery.commons.javaGUIchk
            import lfpBattery.* javax.swing.* java.awt.*
            p = inputParser;
            addOptional(p, 'type', 'DC', @(x) any(validatestring(x, {'DC', 'CL', 'CCCV', 'DIGITIZE'})))
            parse(p, varargin{:})
            %% Create figure
            obj.mainframe = figure('Tag', 'mainframe', 'NumberTitle', 'off', 'Name', 'lfpBattery digitizer and curve fit tool',...
                'IntegerHandle', 'off',...
                'Units', 'normalized',...
                'OuterPosition', [0.0490    0.0972    0.9260    0.8389],...
                'MenuBar','none', 'WindowStyle', 'normal');
            obj.mainframe.CloseRequestFcn = @obj.deleteObj;
            fnt = Font('Helvetica', Font.PLAIN, 13);
            %% Create UI data and axes
            % axes for images to be digitized
            obj.axes1 = axes('Box', 'On', 'BoxStyle', 'Back', 'CLim', [0 1], 'ColorOrder', const.corpDesign,...
                'FontSize', 14, 'Tag', 'axes1', 'Color', [1 1 1], 'XTick', [], 'YTick', []);
            obj.axes1.Position = [0.034 0.057 0.717 0.902];
            obj.axes1.OuterPosition = [-0.074 -0.041 0.904 1.065];
            uifc1 = uiflowcontainer('v0', 'Units', 'norm', 'Position', [0.7940    0.057    0.1708    0.902], 'parent', obj.mainframe, ...
                'FlowDirection', 'TopDown', 'BackgroundColor', [1 1 1]);
            %% title
            title = uiflowcontainer('v0', 'parent', uifc1, 'FlowDirection', 'LeftToRight', ...
                'BackgroundColor', [1 1 1]);
            % TU logo
            str = commons.getHtmlImage('tulogo.png', 'height', '46', 'width', '90');
            jl = JLabel; jl.setText(str)
            jl.setVerticalAlignment(1)
            jl.setOpaque(true);
            jl.setBackground(Color.white);
            javacomponent(jl, [], title);
            % EET logo
            str = commons.getHtmlImage('EETlogo.png', 'height', '46', 'width', '90');
            jl = JLabel; jl.setText(str)
            jl.setVerticalAlignment(1)
            jl.setOpaque(true);
            jl.setBackground(Color.white);
            javacomponent(jl, [], title);
            %% hInfo text box
            obj.hInfo = JLabel;
            obj.hInfo.setText('<html>INFO<br><br>Select curve fit type. Click on "Choose image" button to start...</html>");')
            obj.hInfo.setVerticalAlignment(1)
            obj.hInfo.setFont(fnt);
            javacomponent(obj.hInfo,[], uifc1);
            title.HeightLimits = [10, 60];
            %% Controls
            uifc = uiflowcontainer('v0', 'parent', uifc1, ...
                'FlowDirection', 'BottomUp', 'BackgroundColor', [1 1 1]);
            % list
            obj.list = JList({'discharge curves', 'cycle life curve', 'CCCV curve', 'other'});
            obj.list.setFont(fnt);
            obj.list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
            switch p.Results.type
                case 'DC'
                    ind = 0;
                case 'CL'
                    ind = 1;
                case 'CCCV'
                    ind = 2;
                case 'DIGITIZE'
                    ind = 3;
            end
            obj.list.setSelectedIndex(ind)
            obj.list.setToolTipText(['<html>Selects the type of curve that will be fitted.<br>', ...
                'A discharge curve is a curve of voltage vs. discharge capacity.<br>', ...
                'A cycle life curve is a curve of cycles to failure vs. depth of discharge.<br>', ...
                'A CCCV curve contains 3 curves over the charging time: The current, the voltage and the SoC.<br>', ...
                'The current and SoC curves are required for the CCCV curve fit in order to generate a function<br>', ...
                'Imax = f(SoC)', ...
                'Select "other" for digitizing any curve type without curve fitting.'])
            h = handle(obj.list, 'CallbackProperties');
            h.ValueChangedCallback = @obj.setState;
            javacomponent(obj.list, [], uifc);
            % container for reset button and plot button
            c = uiflowcontainer('v0', 'parent', uifc, 'FlowDirection', 'LeftToRight', ...
                'BackgroundColor', [1 1 1]);
            % plot button
            obj.plotbutton = JButton;
            obj.plotbutton.setText('Plot results');
            obj.plotbutton.setFont(fnt);
            obj.plotbutton.setToolTipText('Plots the digitized data and the curve fit.')
            obj.plotbutton.setEnabled(false);
            javacomponent(obj.plotbutton, [], c);
            plb = handle(obj.plotbutton, 'CallbackProperties');
            set(plb, 'ActionPerformedCallback', @obj.plotResults)
            % reset button
            obj.resetbutton = JButton;
            obj.resetbutton.setText('Reset');
            obj.resetbutton.setFont(fnt);
            obj.resetbutton.setToolTipText('Clears all data and resets this tool.')
            javacomponent(obj.resetbutton, [], c);
            rsb = handle(obj.resetbutton, 'CallbackProperties');
            set(rsb, 'ActionPerformedCallback', @obj.resetbutton_Callback)
            % container for send button and variable name
            toWsp = uiflowcontainer('v0', 'parent', uifc, 'FlowDirection', 'LeftToRight', ...
                'BackgroundColor', [1 1 1]);
            % send button
            obj.sendbutton = JButton;
            obj.sendbutton.setText('To workspace');
            obj.sendbutton.setEnabled(false);
            obj.sendbutton.setFont(fnt);
            obj.sendbutton.setToolTipText('Send the curve fit and raw data to the workspace.')
            javacomponent(obj.sendbutton, [], toWsp);
            rsb = handle(obj.sendbutton, 'CallbackProperties');
            set(rsb, 'ActionPerformedCallback', @obj.sendbutton_Callback)
            % variable name
            obj.varname = JTextField;
            obj.varname.setFont(fnt);
            obj.varname.setText('varName')
            obj.varname.setToolTipText('The variable name of the struct that is sent to the workspace.')
            javacomponent(obj.varname, [], toWsp);
            % select button
            obj.selectbutton = JButton;
            obj.selectbutton.setText('Choose image...');
            obj.selectbutton.setFont(fnt);
            obj.selectbutton.setToolTipText('Choose an image (e. g. a screenshot of a curve a data sheet). Clicking here starts the digitizing walkthrough once an image is selected.')
            javacomponent(obj.selectbutton, [], uifc);
            rsb = handle(obj.selectbutton, 'CallbackProperties');
            set(rsb, 'ActionPerformedCallback', @obj.selectbutton_Callback)
            % save gui data in figure
            guidata(obj.mainframe, obj)
            % initialize states
            obj.states{4} = lfpBattery.digitizeToolOTHER(obj);
            obj.states{3} = lfpBattery.digitizeToolCCCV(obj);
            obj.states{2} = lfpBattery.digitizeToolCL(obj);
            obj.states{1} = lfpBattery.digitizeToolDC(obj);
            obj.state = obj.states{obj.list.getSelectedIndex + 1};
        end
    end
    methods (Hidden)
        function aquiringInfoUpdate(obj, msgStr)
            obj.hInfo.setText(['<html>INFO<br><br>', msgStr{1},'<br><br>', msgStr{2}, '<br><br>', msgStr{3}, '</html>");'])
        end
        function setState(obj, src, ~)
            import lfpBattery.*
            if nargin < 2
                src = obj.list;
            end
            ind = src.getSelectedIndex;
            obj.state = obj.states{ind + 1};
            switch ind
                case 0
                    str = [commons.getHtmlImage('dcurves_qualitative.png'), ...
                        'Selects the type of curve that will be fitted.<br>', ...
                    'A discharge curve plots the voltage against the discharge capacity.'];
                case 1
                    str = [commons.getHtmlImage('wfit_qualitative.png'), ...
                        'Selects the type of curve that will be fitted.<br>', ...
                        'A discharge curve plots the voltage against the discharge capacity.'];
                case 2
                    str = [commons.getHtmlImage('cccv_qualitative.png'), ...
                        'A CCCV curve contains 3 curves over the charging time: The current, the voltage and the SoC.<br>', ...
                        'The current and SoC curves are required for the CCCV curve fit in order to generate a function<br>', ...
                        'Imax = f(SoC)'];
                otherwise
                    str = 'Any type of curve is digitized without curve fitting.';
            end
            src.setToolTipText(str)
        end
    end
    methods (Access = 'protected')
        function selectbutton_Callback(obj, ~, ~)
            import lfpBattery.*
            try
                [pathname, filename] = commons.uigetimage('Choose image', obj.pathcache);
                if isequal(filename, 0) || isequal(pathname, 0)
                    return
                else
                    obj.pathcache(pathname);
                    imagename = fullfile(pathname, filename);
                end
            catch
                waitfor(msgbox('Error reading the file.','ERROR','error'))
                return
            end
            axesreset(obj);
            obj.list.setEnabled(false)
            obj.selectbutton.setEnabled(false)
            obj.sendbutton.setEnabled(false);
            obj.resetbutton.setEnabled(false);
            pic = imread(imagename);
            image(pic)
            set(gca,'YTick',[])
            set(gca,'XTick',[])
            chk = true;
            obj.errCt = 0;
            while chk
                try
                    % Prompt user for X- & Y- values at origin
                    chk = obj.state.getOrigin;
                catch
                    if obj.cancelOrError
                        return
                    end
                end
            end
            obj.errCt = 0;
            % Define X-axis
            chk = true;
            while chk
                try
                    chk = obj.state.getXAxisXdata;
                catch
                    if obj.cancelOrError
                        return
                    end
                end
            end
            obj.errCt = 0;
            % Define Y-axis
            chk = true;
            while chk
                try
                    chk = obj.state.getYAxisYdata;
                catch
                    if obj.cancelOrError
                        return
                    end
                end
            end
            % Complete rotation matrix definition as necessary
            obj.state.rotmatDef;
            % Query number of data sets
            try
                numsets = obj.state.numsets;
                obj.ImgData = repmat(struct(), 1, numsets);
            catch
                cancelandreset(obj);
                waitfor(msgbox('Error!','ERROR','error'))
                return
            end
            cct = 0;
            for si = 1:numsets % Data set loop
                if cct > size(obj.state.colors, 1)
                    cct = 0;
                end
                cct = cct + 1;
                obj.ImgData(si).I = obj.state.I;
                obj.ImgData(si).T = obj.state.T;
                xpt = [];
                ypt = [];
                drawnow
                acquiring = true;
                n = 0;
                obj.aquiringInfoUpdate(obj.state.msgStr);
                while acquiring
                    try
                        [x, y, acquiring, n, addData] = obj.state.getXYpoint(n, cct);
                    catch ME
                        cancelandreset(obj)
                        if strcmp(ME.message, 'Cancelled.')
                            waitfor(msgbox('Cancelled.','CANCELLED','error'))
                        else
                            waitfor(msgbox(ME.message, 'ERROR', 'error'))
                        end
                        return
                    end
                    if addData
                        xpt(n) = x; %#ok<*AGROW>
                        ypt(n) = y;
                    end
                end
                obj.ImgData(si).x = xpt;
                obj.ImgData(si).y = ypt;
            end
            %% Update data
            obj.hInfo.setText('Validation...')
            iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
            iconsSizeEnums = javaMethod('values',iconsClassName);
            SIZE_32x32 = iconsSizeEnums(2);
            jObj = com.mathworks.widgets.BusyAffordance(SIZE_32x32, 'Fitting curves...');
            jObj.setPaintsWhenStopped(true);
            jObj.useWhiteDots(false);
            [~, c] = javacomponent(jObj.getComponent, [10,10,80,80], obj.mainframe);
            c.Units = 'normalized';
            pause(0.2)
            c.Position = [0.7940    0.075    0.1708    0.5];
            jObj.start;
            pause(0.1)
            try
                obj.fit = obj.state.createFit(numsets);
                obj.plotbutton.setEnabled(true);
            catch ME
                warning(ME.message)
                waitfor(msgbox('Creating curve fit failed. Send data to workspace to debug.', 'Fit failed.', 'error'))
            end
            jObj.setBusyText('Done!');
            jObj.stop;
            pause(1)
            delete(c)
            obj.sendbutton.setEnabled(true);
            obj.resetbutton.setEnabled(true);
        end %selectbutton callback
        function plotResults(obj, ~, ~)
            try 
                obj.state.plotResults;
            catch
                
            end
        end
        function deleteObj(obj, ~, ~)
            delete(obj);
            closereq;
        end
        function tf = cancelOrError(obj)
            try
                obj.errCt = obj.errCt + 1;
                if obj.errCt > 5
                    tf = true;
                    cancelandreset(obj);
                    if obj.errCt == 8
                        waitfor(msgbox('Cancelled.','CANCELLED','error'))
                    else
                        waitfor(msgbox('Error!','ERROR','error'))
                    end
                else
                    tf = false;
                end
            catch
                % User closed figure and deleted object while selecting
                % data
                tf = true;
            end
        end
        function sendbutton_Callback(obj, ~, ~) %#ok<*INUSD>
            if obj.externalControl
                try
                    [fname, fpath] = uiputfile('*.mat','Save MAT file As');
                    fit = obj.fit; %#ok<NASGU,PROPLC>
                    raw = obj.ImgData; %#ok<NASGU>
                    save(fullfile(fpath, fname), 'raw', 'fit')
                catch
                    waitfor(msgbox('Failed to save curve fit.','ERROR','error'))
                end
            else
                try
                    mname = char(obj.varname.getText);
                    s = struct;
                    s.raw = obj.ImgData;
                    s.fit = obj.fit;
                    assignin('base', mname, s)
                catch
                    waitfor(msgbox('Failed to send curve fit to workspace.','ERROR','error'))
                end
            end
        end % sendbutton_Callback
        
        function resetbutton_Callback(obj, ~, ~) %#ok<*INUSL>
            obj.cancelandreset();
        end % resetbutton_Callback
        
        function obj = cancelandreset(obj)
            obj.plotbutton.setEnabled(false);
            obj.selectbutton.setEnabled(true)
            obj.resetbutton.setEnabled(true)
            obj.sendbutton.setEnabled(false)
            if ~obj.externalControl
                obj.list.setEnabled(true)
            end
            obj.varname.setText('varName')
            obj.axesreset();
            ylabel('')
            xlabel('')
            set(obj.axes1,'Box','on')
            obj.hInfo.setText('<html>INFO<br><br>Select curve fit type. Click on "Choose image" button to start...</html>");')
        end % cancelandreset
        
        function obj = axesreset(obj)
            cla(obj.axes1,'reset')
            set(obj.axes1,'XTick',[])
            set(obj.axes1,'YTick',[])
            set(obj.axes1,'Color',[1 1 1])
            set(obj.axes1,'ColorOrder',lfpBattery.const.corpDesign)
        end
        
    end
    
    methods (Static)
        function lockPointer(xp, axis)
            %LOCKPOINTER: Add this to a listener for a figure's 'WindowMouseMotion'
            %event to lock the cursor horizontally or vertically.
            %
            %Syntax: setPointer(xp, axis)
            %
            %xp:    pointer pixel position of format [x, y]
            %axis:  'x' to lock to vertical line (locks x position)
            %       'y' to lock to horizontal line (locks y position)
            %
            %Usage example:
            % fig = figure;
            % ax = axes;
            % [xx(2), yy(2)] = ginput(1);
            % x_p = get(0, 'PointerLocation');
            % % other code
            % hL = addlistener(fig,'WindowMouseMotion', @(x, y) digitizeTool.lockPointer(x_p, 'x'));
            % [xx(1), yy(1)] = ginput(1);
            % delete(hL)
            %
            %Author: Marc Jakobi, 07. February 2017
            if strcmp(axis, 'x')
                ind = 1;
            elseif strcmp(axis, 'y')
                ind = 2;
            else
                error('Second argument must be ''x'' or ''y''.')
            end
            x = get(0, 'PointerLocation');
            x(ind) = xp(ind);
            set(0, 'PointerLocation', x);
        end % lockpointer
    end
    methods (Static, Access = 'protected')
        function path = pathcache(path)
            persistent pathname;
            if nargin > 0
                pathname = path;
            elseif isempty(pathname)
                pathname = pwd;
            end
            if nargout > 0
                path = pathname;
            end
        end % pathcache
    end
end
