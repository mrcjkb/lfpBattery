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
    end
    properties (Hidden, Access = 'protected')
        axes1;
        Information;
        resetbutton;
        selectbutton;
        xLabel;
        yLabel;
        Oxdata;
        Oydata;
        xdef = 0;
        ydef = 0;
        type; % 0 for discharge curves, 1 for woehler fit
    end
    methods
        function obj = digitizeTool()
            lfpBattery.commons.javaGUIchk
            import lfpBattery.* javax.swing.* java.awt.*
            %% Create figure
            obj.mainframe = figure('Tag', 'mainframe', 'NumberTitle', 'off', 'Name', 'lfpBattery digitizer and curve fit tool',...
                'IntegerHandle', 'off',...
                'Units', 'normalized',...
                'OuterPosition', [0.0490    0.0972    0.9260    0.8389],...
                'MenuBar','none', 'WindowStyle', 'normal');
            fnt = Font('Helvetica', Font.PLAIN, 13);
            %% Create UI data and axes
            % axes for images to be digitized
            obj.axes1 = axes('Box', 'On', 'BoxStyle', 'Back', 'CLim', [0 1], 'ColorOrder', const.corpDesign,...
                'FontSize', 14, 'Tag', 'axes1', 'Color', [1 1 1], 'XTick', [], 'YTick', []);
            obj.axes1.Position = [0.034 0.057 0.717 0.902];
            obj.axes1.OuterPosition = [-0.074 -0.041 0.904 1.065];
            %             obj.axes1.CreateFcn = @(obj.selectbutton,eventdata)ICdigitizer('axes1_CreateFcn',obj.selectbutton,eventdata,guidata(obj.selectbutton));
            % information text box
            obj.Information = JLabel;
            obj.Information.setText('<html>INFO<br><br>Select curve fit type and choose file...</html>");')
            obj.Information.setVerticalAlignment(1)
            obj.Information.setFont(fnt);
            [~, container] = javacomponent(obj.Information);
            container.Units = 'normalized';
            container.Position = [0.7940    0.075    0.1708    0.5];
            % list
            obj.list = JList({'discharge curves', 'cycle life curve'});
            obj.list.setFont(fnt);
            obj.list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
            obj.list.setSelectedIndex(0)
            obj.list.setToolTipText(['<html>Selects the type of curve that will be fitted.<br>', ...
                'A discharge curve is a curve of voltage vs. discharge capacity.<br>',...
                'A cycle life curve is a curve of cycles to failure vs. depth of discharge.</html>");'])
            [~, container] = javacomponent(obj.list);
            container.Units = 'normalized';
            container.Position = [0.7940    0.7    0.1708    0.0684];
            % reset button
            obj.resetbutton = JButton;
            obj.resetbutton.setText('Reset');
            obj.resetbutton.setFont(fnt);
            obj.resetbutton.setToolTipText('Clears all data and resets this tool.')
            [~, container] = javacomponent(obj.resetbutton);
            container.Units = 'normalized';
            container.Position = [0.7940    0.7846    0.1708    0.0484];
            rsb = handle(obj.resetbutton, 'CallbackProperties');
            set(rsb, 'ActionPerformedCallback', @obj.resetbutton_Callback)
            % send button
            obj.sendbutton = JButton;
            obj.sendbutton.setText('To workspace');
            obj.sendbutton.setEnabled(false);
            obj.sendbutton.setFont(fnt);
            obj.sendbutton.setToolTipText('Send the curve fit and raw data to the workspace.')
            [~, container] = javacomponent(obj.sendbutton);
            container.Units = 'normalized';
            container.Position = [0.7940    0.8423    0.085    0.0484];
            rsb = handle(obj.sendbutton, 'CallbackProperties');
            set(rsb, 'ActionPerformedCallback', @obj.sendbutton_Callback)
            % variable name
            obj.varname = JTextField;
            obj.varname.setFont(fnt);
            obj.varname.setText('varName')
            obj.varname.setToolTipText('The variable name of the struct that is sent to the workspace.')
            [~, container] = javacomponent(obj.varname);
            container.Units = 'normalized';
            container.Position = [0.88    0.8423    0.0854    0.0484];
            % select button
            obj.selectbutton = JButton;
            obj.selectbutton.setText('Choose image...');
            obj.selectbutton.setFont(fnt);
            obj.selectbutton.setToolTipText('Choose an image (e. g. a screenshot of a curve a data sheet). Clicking here starts the digitizing walkthrough once an image is selected.')
            [~, container] = javacomponent(obj.selectbutton);
            container.Units = 'normalized';
            container.Position = [0.7940    0.9    0.1708    0.0484];
            rsb = handle(obj.selectbutton, 'CallbackProperties');
            set(rsb, 'ActionPerformedCallback', @obj.selectbutton_Callback)
            % save gui data in figure
            guidata(obj.mainframe, obj)
        end
    end
    methods(Access='protected')
        function obj = selectbutton_Callback(obj, ~, ~)
            import lfpBattery.*
            try
                [filename, pathname] = uigetfile( ...
                    {'*.jpg;*.tif;*.tiff;*.gif;*.png;*.bmp', ...
                    'All supported file types (*.jpg,*.tif,*.tiff,*.gif,*.png,*.bmp)'; ...
                    '*.jpg;*.jpeg', ...
                    'JPEG files (*.jpg,*.jpeg)'; ...
                    '*.tif;*.tiff', ...
                    'TIFF filles (*.tif,*.tiff)'; ...
                    '*.gif', ...
                    'GIF files (*.gif)'; ...
                    '*.png', ...
                    'PNG files (*.png)'; ...
                    '*.bmp', ...
                    'Bitmap files (*.bmp)'; ...
                    '*.*', ...
                    'All file types (*.*)'}, ...
                    'Choose image');
                if isequal(filename,0) || isequal(pathname,0)
                    return
                else
                    imagename = fullfile(pathname, filename);
                end
            catch
                waitfor(msgbox('Error reading the file.','ERROR','error'))
                return
            end
            axesreset(obj);
            obj.type = obj.list.getSelectedIndex; % 0 = dischargeCurves, 1 = woehlerFit
            if obj.type == 0
                obj.xLabel = 'discharge capacity in Ah';
                obj.yLabel = 'voltage in V';
            else
                obj.xLabel = 'depth of discharge';
                obj.yLabel = 'cycles to failure';
            end
            obj.list.setEnabled(false)
            obj.selectbutton.setEnabled(false)
            obj.sendbutton.setEnabled(false);
            obj.resetbutton.setEnabled(false);
            pic = imread(imagename);
            image(pic)
            set(gca,'YTick',[])
            set(gca,'XTick',[])
            hInfo = obj.Information;
            chk = true;
            ct = 0;
            while chk
                try
                    % Determine location of origin with mouse click
                    msg = 'Select the ORIGIN with the left mouse button.';
                    OriginButton = questdlg(msg, ...
                        'Input', ...
                        'OK','Cancel','OK');
                    hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
                    switch OriginButton
                        case 'OK'
                            drawnow
                            [Xopixels,Yopixels] = ginput(1);
                            inp = line(Xopixels,Yopixels,...
                                'Marker', 'o', 'Color', const.green, 'MarkerSize', 14);
                            inp2 = line(Xopixels,Yopixels,...
                                'Marker', 'x', 'Color', const.green, 'MarkerSize', 14);
                        case 'Cancel'
                            ct = 7;
                            error('cancelled')
                    end % switch OriginButton
                    % Prompt user for X- & Y- values at origin
                    prompt={['Abscissa (', obj.xLabel ,') at origin:'] ,...
                        ['Ordinate (', obj.yLabel, ') at origin:'],...
                        'Repeat selection? (Y/N)'};
                    if strcmp(obj.selectbutton.getText,'Choose image...')
                        def={'0','0','N'};
                    else
                        def = {obj.Oxdata, obj.Oydata, 'N'};
                    end
                    dlgTitle='User input';
                    lineNo=1;
                    hInfo.setText(['<html>INFO<br><br>', prompt{1}, '<br>', prompt{2} '</html>");'])
                    answer=inputdlg(prompt,dlgTitle,lineNo,def);
                    if (isempty(char(answer{:})) == 1)
                        ct = 7;
                        error('cancelled')
                    elseif strcmp(char(answer{3}), 'Y')
                        delete(inp)
                        delete(inp2)
                        error('chk')
                    else
                        answer = answer(1:2);
                        obj.Oxdata = char(answer{1});
                        obj.Oydata = char(answer{2});
                        OriginXYdata = [str2double(char(answer{1}));...
                            str2double(char(answer{2}))];
                        chk = false;
                    end
                catch
                    ct = ct + 1;
                    if ct > 5
                        cancelandreset(obj);
                        if ct == 8
                            waitfor(msgbox('Cancelled.','CANCELLED','error'))
                        else
                            waitfor(msgbox('Error!','ERROR','error'))
                        end
                        return
                    end
                end
            end
            chk = true;
            ct = 0;
            while chk
                try
                    msg = ['Select a coordinate on the abscissa (', obj.xLabel, ') with the left mouse button.'];
                    hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
                    XLimButton = questdlg(...
                        msg, ...
                        'Tutorial', ...
                        'OK','Cancel','OK');
                    switch XLimButton
                        case 'OK'
                            drawnow
                            [XAxisXpixels,XAxisYpixels] = ginput(1);
                            inp = line(XAxisXpixels,XAxisYpixels,...
                                'Marker','*','Color', const.green,'MarkerSize',14);
                            inp2 = line(XAxisXpixels,XAxisYpixels,...
                                'Marker','s','Color', const.green,'MarkerSize',14);
                        case 'Cancel'
                            ct = 7;
                            error('cancelled')
                    end
                    % Prompt user for XLim value
                    msg = [obj.xLabel, ' at the selected coordinate:'];
                    hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
                    prompt={msg;...
                        'Repeat? (Y/N)'};
                    def={'3','N'};
                    dlgTitle = 'User input';
                    lineNo = 1;
                    answer = inputdlg(prompt,dlgTitle,lineNo,def);
                    if (isempty(char(answer{:})) == 1)
                        ct = 7;
                        error('cancelled')
                    elseif strcmp(answer{2},'Y')
                        delete(inp)
                        delete(inp2)
                        error('chk')
                    else
                        answer = answer(1);
                        XAxisXdata = str2double(char(answer{:}));
                        obj.xdef = num2str(XAxisXdata);
                        chk = false;
                    end
                catch
                    ct = ct + 1;
                    if ct > 5
                        cancelandreset(obj);
                        if ct == 8
                            waitfor(msgbox('Cancelled.','CANCELLED','error'))
                        else
                            waitfor(msgbox('Error!','ERROR','error'))
                        end
                        return
                    end
                end
            end
            %scale x axis
            Xtype = questdlg(...
                'Axis scaling (X)', ...
                'Walkthrough', ...
                'LINEAR','LOGARITHMIC','CANCEL','LINEAR');
            drawnow
            switch Xtype
                case 'LINEAR'
                    logx = false;
                    scalefactorXdata = XAxisXdata - OriginXYdata(1);
                case 'LOGARITHMIC'
                    logx = true;
                    scalefactorXdata = log10(XAxisXdata/OriginXYdata(1));
                case 'CANCEL'
                    cancelandreset(obj);
                    return
            end
            % Rotate image if necessary
            % note image file line 1 is at top
            th = atan((XAxisYpixels-Yopixels)/(XAxisXpixels-Xopixels));
            % axis rotation matrix
            rotmat = [cos(th) sin(th); -sin(th) cos(th)];
            % Define Y-axis
            chk = true;
            ct = 0;
            while chk
                try
                    msg = ['Select a coordinate on the ordinate (', obj.yLabel, ') with the left mouse button.'];
                    hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
                    YLimButton = questdlg(...
                        msg, ...
                        'Tutorial', ...
                        'OK','Cancel','OK');
                    switch YLimButton
                        case 'OK'
                            drawnow
                            [YAxisXpixels,YAxisYpixels] = ginput(1);
                            inp = line(YAxisXpixels,YAxisYpixels,...
                                'Marker','*','Color',const.green,'MarkerSize',14);
                            inp2 = line(YAxisXpixels,YAxisYpixels,...
                                'Marker','s','Color',const.green,'MarkerSize',14);
                        case 'Cancel'
                            ct = 7;
                    end
                    % Prompt user for YLim value
                    msg = [obj.yLabel, ' at the selected coordinate:'];
                    hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
                    prompt={msg,...
                        'Repeat? (Y/N)'};
                    def={'3','N'};
                    dlgTitle='User input';
                    lineNo=1;
                    answer=inputdlg(prompt,dlgTitle,lineNo,def);
                    if (isempty(char(answer{:})) == 1)
                        ct = 7;
                        error('cancelled')
                    elseif strcmp(answer{2},'Y')
                        delete(inp)
                        delete(inp2)
                        error('chk')
                    else
                        answer = answer(1);
                        YAxisYdata = str2double(char(answer{:}));
                        chk = false;
                    end
                catch
                    ct = ct + 1;
                    if ct > 5
                        cancelandreset(obj);
                        if ct == 8
                            waitfor(msgbox('Cancelled.','CANCELLED','error'))
                        else
                            waitfor(msgbox('Error!','ERROR','error'))
                        end
                        return
                    end
                end
            end
            % Determine Y-axis scaling
            Ytype = questdlg('Axis scaling (Y)', ...
                'Walkthrough', ...
                'LINEAR','LOGARITHMIC','CANCEL','LINEAR');
            drawnow
            switch Ytype
                case 'LINEAR'
                    logy = false;
                    scalefactorYdata = YAxisYdata - OriginXYdata(2);
                case 'LOGARITHMIC'
                    logy = true;
                    scalefactorYdata = log10(YAxisYdata/OriginXYdata(2));
                case 'CANCEL'
                    cancelandreset(obj);
                    return
            end
            % Complete rotation matrix definition as necessary
            delxyx = rotmat*[(XAxisXpixels-Xopixels);(XAxisYpixels-Yopixels)];
            delxyy = rotmat*[(YAxisXpixels-Xopixels);(YAxisYpixels-Yopixels)];
            delXcal = delxyx(1);
            delYcal = delxyy(2);
            if obj.type == 0 % discharge curve
                dlgTitle='User input';
                lineNo = 1;
                def = {'5'};
                prompt = 'Please type in the number of curves to digitize.';
                hInfo.setText(['<html>INFO<br><br>', prompt, '</html>");'])
                try
                    chk = true;
                    while chk
                        answer = inputdlg(prompt,dlgTitle,lineNo,def);
                        numsets = round(str2double(char(answer{:})));
                        if numsets <= 0
                            waitfor(msgbox('Please insert a number greater than 0.','ERROR','error'))
                        else
                            chk = false;
                        end
                    end
                    obj.ImgData = repmat(struct(),1,numsets);
                catch
                    cancelandreset(obj);
                    waitfor(msgbox('Error!','ERROR','error'))
                    return
                end
            else % woehler curve
                numsets = 1;
                obj.ImgData = repmat(struct(),1,numsets);
            end
            colors = const.corpDesign;
            corrpossible = false; %for checking if correction is possible
            cct = 0;
            for si = 1:numsets % Data set loop
                if cct > size(colors, 1)
                    cct = 0;
                end
                cct = cct + 1;
                dlgTitle='User input';
                lineNo = 1;
                def = {'1'};
                if obj.type == 0
                    prompt = 'Please type in the current in A.';
                    hInfo.setText(['<html>INFO<br><br>', prompt, '</html>");'])
                    chk = true;
                    while chk
                        answer = inputdlg(prompt,dlgTitle,lineNo,def);
                        I = round(str2double(char(answer{:})));
                        if I <= 0
                            waitfor(msgbox('Please insert a number greater than 0.','ERROR','error'))
                        else
                            chk = false;
                        end
                    end
                    def = {'20'};
                    prompt = 'Please type in the temperature in °C.';
                    hInfo.setText(['<html>INFO<br><br>', prompt, '</html>");'])
                    chk = true;
                    while chk
                        answer = inputdlg(prompt,dlgTitle,lineNo,def);
                        T = round(str2double(char(answer{:}))) + 273.15;
                        if T < 0
                            waitfor(msgbox('Please insert a number greater than -273.15.','ERROR','error'))
                        else
                            chk = false;
                        end
                    end
                    obj.ImgData(si).I = I;
                    obj.ImgData(si).T = T;
                else
                    obj.ImgData.I = [];
                    obj.ImgData.T = [];
                end
                xpt = [];
                ypt = [];
                msgStr = cell(1,5);
                % Commence Data Acquisition from image
                msgStr{1} = 'Select data points with the LEFT mouse button.';
                msgStr{2} = ' ';
                msgStr{3} = 'Correction with the MIDDLE mouse button.';
                msgStr{4} = ' ';
                msgStr{5} = 'RIGHT click, when done.';
                hInfo.setText(['<html>INFO<br><br>', msgStr{1},'<br><br>', msgStr{3}, '<br><br>', msgStr{5}, '</html>");'])
% Removed this, as it gets annoying over time
%                 if numsets == 1
%                     titleStr = 'Ready to extract data set';
%                 else
%                     titleStr = ['Ready to extract data set' ,num2str(si),' of ',...
%                         num2str(numsets),'.'];
%                 end
%                 uiwait(msgbox(msgStr,titleStr,'warn','modal'));
                drawnow
                %numberformat = '%6.2f';
                nXY = [];
                ng = 0;
                acquiring = true;
                n = 0;
                while acquiring
                    [x,y, buttonNumber] = ginput(1);
                    if buttonNumber == 1
                        aqmarker = line(x,y,'Marker','.','Color',colors(cct, :),'MarkerSize',12);
                        xy = rotmat*[(x-Xopixels);(y-Yopixels)];
                        delXpoint = xy(1);
                        delYpoint = xy(2);
                        msgStr{3} = 'Correction with the MIDDLE mouse button.';
                        hInfo.setText(['<html>INFO<br><br>', msgStr{1},'<br><br>', msgStr{3}, '<br><br>', msgStr{5}, '</html>");'])
                        if logx
                            x = OriginXYdata(1) .* 10 .^ (delXpoint ./ delXcal .* scalefactorXdata);
                        else
                            x = OriginXYdata(1) + delXpoint ./ delXcal .* scalefactorXdata;
                        end
                        if logy
                            y = OriginXYdata(2) .* 10 .^ (delYpoint ./ delYcal .* scalefactorYdata);
                        else
                            y = OriginXYdata(2) + delYpoint ./ delYcal .* scalefactorYdata;
                        end
                        n = n + 1;
                        xpt(n) = x; %#ok<*AGROW>
                        ypt(n) = y;
                        ng = ng+1;
                        nXY(ng,:) = [n x y];
                        corrpossible = true;
                    elseif buttonNumber == 3 && n == 0
                        query = questdlg('No data selected. Cancel?', ...
                            'CANCEL?', ...
                            'YES', 'NO', 'NO');
                        drawnow
                        if strcmpi(query,'YES')
                            cancelandreset(obj);
                            waitfor(msgbox('Cancelled.','CANCELLED','error'))
                            return
                        end
                    elseif buttonNumber == 3
                        query = questdlg('Done?', ...
                            'CONFIRM', ...
                            'YES', 'NO', 'NO');
                        drawnow
                        if strcmpi(query,'YES')
                            acquiring = false;
                        end
                    elseif buttonNumber == 2 && corrpossible
                        query = questdlg('Correct last point?', ...
                            'CORRECTION?', ...
                            'CORRECTION', 'CONTINUE', 'CONTINUE');
                        drawnow
                        if strcmpi(query,'CORRECTION')
                            delete(aqmarker);
                            n = n - 1;
                            ng = ng - 1;
                            corrpossible = false;
                            msgStr{3} = 'Correction...';
                            hInfo.setText(['<html>INFO<br><br>', msgStr{1},'<br><br>', msgStr{3}, '<br><br>', msgStr{5}, '</html>");'])
                        end
                    end
                end
                obj.ImgData(si).x = xpt;
                obj.ImgData(si).y = ypt;
            end
            %% Update UD
            hInfo.setText('Validation...')
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
            if obj.type == 0
                obj.fit = dischargeCurves;
                for si = 1:numsets
                    df = dischargeFit(obj.ImgData(si).y, obj.ImgData(si).x, obj.ImgData(si).I, obj.ImgData(si).T);
                    obj.fit.add(df);
                end
                obj.fit.plotResults
            else
                obj.fit = woehlerFit(obj.ImgData(1).x, obj.ImgData(1).y); %(N, DoD)
                obj.fit.plotResults(true)
            end
            jObj.setBusyText('Done!');
            jObj.stop;
            delete(c)
            obj.sendbutton.setEnabled(true);
            obj.resetbutton.setEnabled(true);
        end %selectbutton callback
        
        function sendbutton_Callback(obj, ~, ~) %#ok<*INUSD>
            try
                mname = char(obj.varname.getText);
                s = struct;
                s.raw = obj.ImgData;
                s.fit = obj.fit;
                assignin('base', mname, s)
            catch
                waitfor(msgbox('Failed to send curve fit to workspace.','ERROR','error'))
            end
        end % sendbutton_Callback
        
        function resetbutton_Callback(obj, ~, ~) %#ok<*INUSL>
            obj.cancelandreset();
        end % resetbutton_Callback
        
        function obj = cancelandreset(obj)
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
            obj.Information.setText('<html>INFO<br><br>Select curve fit type and choose file...</html>");')
        end % cancelandreset
        
        function obj = axesreset(obj)
            cla(obj.axes1,'reset')
            set(obj.axes1,'XTick',[])
            set(obj.axes1,'YTick',[])
            set(obj.axes1,'Color',[1 1 1])
            set(obj.axes1,'ColorOrder',lfpBattery.const.corpDesign)
        end
    end
end

