classdef bpackGUI < handle
    %BPACKGUI: Opens a GUI for initializing batteryPack models. 
    
    properties
        f; % figure handle
        jcb1; % JComboBox for setup
        cpL = cell(6,1); % cell and pack voltage /capacity labels
        cpE = cell(6,1); % cell and pack voltage / capacity edits
        jcbA; % JComboBox for age model
        jcbEQ; % JComboBox for equalization
        eta = cell(2, 1); % JTextPanes for charging and discharging efficiencies
        simple; % JCheckBox for simplified model
        psd; % Self-discharge rate
        soc = cell(3, 1); % ini, min, max
        soh; % initial state of health
        topology;
        Zi = cell(4, 1); % mean, std, min, max
        dC = 'none'; % discharge curve
        wF = 'none'; % woehler fit
        cC = 'none'; % cccv curve
        cC2 = 'none'; % charge curve or discharge curve used for charging
        wfButton = cell(2, 1);
        varname;
    end
    
    methods
        function b = bpackGUI
            lfpBattery.commons.javaGUIchk
            import lfpBattery.* javax.swing.* java.awt.*
            %% Set up GUI
            b.f = figure('Tag', 'mainframe', 'NumberTitle', 'off', 'Name', 'batteryPack GUI',...
                'IntegerHandle', 'off',...
                'Units', 'normalized',...
                'MenuBar','none', 'WindowStyle', 'normal', ...
                'Color', [1 1 1], 'Visible', 'off', 'Tag', 'bpackGUI');
            b.f.Position(3) = 2.2 .* b.f.Position(3);
            b.f.Position(4) = 1.2 .* b.f.Position(4);
            movegui(b.f, 'center')
            mainlayout = uiflowcontainer('v0', 'Units', 'norm', 'Position', [.05, .05, .9, .9], 'parent', b.f, ...
                'FlowDirection', 'TopDown', 'BackgroundColor', [1 1 1]);
            %% Title container
            title = uiflowcontainer('V0', 'parent', mainlayout, 'FlowDirection', 'LeftToRight', ...
                'BackgroundColor', [1 1 1]);
            title.HeightLimits = [10, 60];
            logo = uiflowcontainer('v0', 'parent', title, 'FlowDirection', 'LeftToRight', ...
                'BackgroundColor', [1 1 1]);
            %% TU logo
            str = commons.getHtmlImage('tulogo.png', 'height', '46', 'width', '90');
            jl = JLabel; jl.setText(str)
            jl.setVerticalAlignment(1)
            jl.setOpaque(true);
            jl.setBackground(Color.white);
            javacomponent(jl, [], logo);
            %% EET logo
            str = commons.getHtmlImage('EETlogo.png', 'height', '46', 'width', '90');
            jl = JLabel; jl.setText(str)
            jl.setVerticalAlignment(1)
            jl.setOpaque(true);
            jl.setBackground(Color.white);
            javacomponent(jl, [], logo);
            %% Authors
            str = ['<html><div align="right">Battery Pack Designer v.1.0<br>Marc Jakobi, Festus Angangbe, Marc Schmidt',...
                '<br>TU Berlin, 2017</div>'];
            jl = JLabel; jl.setText(str)
            jl.setVerticalAlignment(1)
            jl.setHorizontalAlignment(SwingConstants.RIGHT)
            jl.setOpaque(true);
            jl.setBackground(Color.white);
            javacomponent(jl, [], logo);
            %% Main layout
            layout = uiflowcontainer('v0', 'parent', mainlayout, 'FlowDirection', 'LeftToRight', ...
                'BackgroundColor', [1 1 1]);
            hc = uiflowcontainer('v0', 'parent', layout, 'FlowDirection', 'BottomUp');
            %% Cell and pack voltages and capacities
            labels = {'<html>Cell capacity<br>in Ah:</html>")', '<html>Cell voltage<br>in V:</html>")', ...
                '<html>Pack capacity<br>in Ah:</html>")', '<html>Pack voltage<br>in V:</html>")', ...
                '<html>Number of<br>parallel cells:</html>")', '<html>Number of<br>cells in series:</html>")'};
            def = {'3', '3.2', '390', '12.8', '130', '4'};
            for i = 1:6
                cc = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
                jl = JLabel; jl.setText(labels{i})
                jl.setVerticalAlignment(1)
                javacomponent(jl, [], cc);
                b.cpL{i} = jl;
                jt = JTextPane;
                jt.setText(def{i})
                javacomponent(jt, [], cc);
                b.cpE{i} = jt;
            end
            for i = 1:4
                b.cpE{i}.setToolTipText(labels{i}(1:end-1))
            end
            b.cpE{5}.setToolTipText('The pack''s total capacity increases with the number of parallel cells.')
            b.cpE{6}.setToolTipText('The pack''s total voltage increases with the number of cells in series.')
            for i = 3:4
                h = handle(b.cpE{i}, 'CallbackProperties');
                h.KeyTypedCallback = @b.calcN;
            end
            for i = 5:6
                h = handle(b.cpE{i}, 'CallbackProperties');
                h.KeyTypedCallback = @b.calcCV;
                b.cpE{i}.setEnabled(false)
            end
            %% set-up 'Auto' or 'Manual'
            b.jcb1 = JComboBox({b.multiline('Auto setup', 'based on pack size'), 'Manual setup'});
            javacomponent(b.jcb1, [], hc);
            b.jcb1.setToolTipText(['<html>Auto setup based on pack size:<br>', ...
                'Attempts to estimate the number of cells in series/parallel<br>',...
                'so that the pack has approximately the specified nominal capacity and voltage<br><br>',...
                'Manual setup: Specify the number of cells in series/parallel manually.<br>',...
                'The pack''s nominal voltage and capacity are calculated accordingly.</html>");'])
            h = handle(b.jcb1, 'CallbackProperties');
            h.ActionPerformedCallback = @b.switchSetup;
            %% age model
            hc = uiflowcontainer('v0', 'parent', layout, 'FlowDirection', 'TopDown');
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            des = JLabel; des.setText('Age model:')
            des.setVerticalAlignment(1)
            javacomponent(des, [], u);
            b.jcbA = JComboBox({'none', 'pack level', 'cell level'});
            b.jcbA.setToolTipText(['<html>cell level: Age model is calculated separately for each cell (slower)<br><br>', ...
                'pack level: Age model is calculated for pack (faster)<br><br>', ...
                'none: Age model is ignored (fastest)</html>")'])
            javacomponent(b.jcbA, [], u);
            h = handle(b.jcbA, 'CallbackProperties');
            h.ActionPerformedCallback = @b.ageModelChange;
            %% Equalization
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            des = JLabel; des.setText('Equalization:')
            des.setVerticalAlignment(1)
            javacomponent(des, [], u);
            b.jcbEQ = JComboBox({'active', 'passive'});
            b.jcbEQ.setSelectedIndex(1)
            b.jcbEQ.setToolTipText(b.multiline('The balancing of voltage and capacity accross string elements.', ...
                'In the simplified model, passive equalization is not possible.'))
            javacomponent(b.jcbEQ, [], u);
            %% charging and discharging efficiencies
            labels = {'<html>Charging<br>efficiency:</html>', '<html>Discharging<br>efficiency:</html>")'};
            tooltip = 'Please insert a value between 0 and 1.';
            def = {'0.97', '0.97'};
            jl = cell(2,1);
            for i = 1:2
                u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
                jl{i} = JLabel; jl{i}.setText(labels{i})
                jl{i}.setVerticalAlignment(1)
                javacomponent(jl{i}, [], u);
                jt = JTextPane;
                jt.setText(def{i})
                javacomponent(jt, [], u);
                b.eta{i} = jt;
                h = handle(b.eta{i}, 'CallbackProperties');
                h.KeyTypedCallback = @b.lim01;
                b.eta{i}.setToolTipText(tooltip)
            end
            %% self-discharge rate
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            txt = b.multiline('Self-discharge rate','in 1/month:');
            jl = JLabel; jl.setText(txt)
            javacomponent(jl, [], u);
            jl.setVerticalAlignment(1)
            jt = JTextPane;
            jt.setText('0')
            javacomponent(jt, [], u);
            b.psd = jt;
            h = handle(jt, 'CallbackProperties');
            h.KeyTypedCallback = @b.lim01;
            b.psd.setToolTipText('If the self-discharge rate is 1 % per month, set this value to 0.01.')
            %% SoC
            jl = JLabel; jl.setText('State of charge SoC')
            jl.setHorizontalAlignment(0)
            javacomponent(jl, [], hc);
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            txt = {'Initial:', 'Minimum:', 'Maximum:'};
            def = {'0.2', '0.2', '1'};
            tooltips = {'The SoC of the battery pack at the beginning of the simulation.', ...
                'Most lithium ion batteries have a lower SoC limitation of 0.1 to 0.2 for safety reasons.', ...
                'In some cases, it may make sense to limit the maximum SoC, for example for slower aging.'};
            for i = 1:3
                uu =  uiflowcontainer('v0', 'parent', u, 'FlowDirection', 'TopDown');
                jl = JLabel; jl.setText(txt{i})
                jl.setVerticalAlignment(1)
                javacomponent(jl, [], uu);
                jt = JTextPane;
                jt.setText(def{i})
                javacomponent(jt, [], uu);
                b.soc{i} = jt;
                h = handle(b.soc{i}, 'CallbackProperties');
                h.KeyTypedCallback = @b.lim01;
                b.psd.setToolTipText(tooltips{i})
            end
            %% Checkbox for simplified model
            b.simple = JCheckBox('Simplified model', false);
            javacomponent(b.simple, [], hc);
            %% SoH
            hc = uiflowcontainer('v0', 'parent', layout, 'FlowDirection', 'TopDown');
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            jl = JLabel; jl.setText(b.multiline('State of health','SoH:'))
            javacomponent(jl, [], u);
            jl.setVerticalAlignment(1)
            jt = JTextPane;
            jt.setText('1')
            javacomponent(jt, [], u);
            b.soh = jt;
            b.soh.setToolTipText(b.multiline('The state of health SoH at the beginning of the simulation.',...
                'If no age model is selected, this property can still be set.', ...
                'Must be a value between 0 and 1'))
            %% Topology
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            des = JLabel; des.setText('Topology:')
            des.setVerticalAlignment(1)
            javacomponent(des, [], u);
            b.topology = JComboBox({'SP', 'PS'});
            str = [commons.getHtmlImage('topologies.png'), ...
                'The topology may influence the equalization.'];
            b.topology.setToolTipText(str)
            javacomponent(b.topology, [], u);
            %% Zi & Zgauss
            jl = JLabel; jl.setText('<html>Internal impedance in &#937</html>')
            jl.setHorizontalAlignment(0)
            javacomponent(jl, [], hc);
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            txt = {'Mean:', b.multiline('Standard', 'deviation:'), 'Minimum:', 'Maximum:'};
            def = {'17e-3', '0', '17e-3', '17e-3'};
            tooltips = b.multiline('The proportions of the internal impedances of the cells are used to determine voltage and current distributions.', ...
                'In order to define a standard distribution, the statistics toolbox is required.', ...
                'If a gaussian distribution is set, it should be limited to realistic values.');
            for i = 1:4
                uu =  uiflowcontainer('v0', 'parent', u, 'FlowDirection', 'TopDown');
                jl = JLabel; jl.setText(txt{i})
                jl.setVerticalAlignment(1)
                javacomponent(jl, [], uu);
                jt = JTextPane;
                jt.setText(def{i})
                javacomponent(jt, [], uu);
                b.Zi{i} = jt;
                b.Zi{i}.setToolTipText(tooltips)
            end
            if ~license('test', 'statistics_toolbox')
                for i = 2:3
                    b.Zi{i}.setEnabled(0)
                end
            end
            % set callbacks
            h = handle(b.simple, 'CallbackProperties');
            h.ActionPerformedCallback = @b.simplify;
            %% Curve fits
            hc = uiflowcontainer('v0', 'parent', layout, 'FlowDirection', 'TopDown');
            %% Discharge Curve fits
            jl = JLabel; jl.setText('Discharge curve fits:')
            jl.setHorizontalAlignment(0)
            str = [commons.getHtmlImage('dcurves_qualitative.png'), ...
                'A discharge curve plots the voltage against the discharge capacity.'];
            jl.setToolTipText(str)
            javacomponent(jl, [], hc);
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            jb = JButton('Load demo data');
            jb.setToolTipText('Loads the discharge curve of a BMZ BM26650ETC1 li-ion cell.')
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.loadDCDemo;
            jb = JButton(b.multiline('Start digitize', 'and fit tool'));
            jb.setToolTipText('Starts a tool for digitizing images and fitting the discharge curves.')
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.startDCFitTool;
            %% Charge Curve fits
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            jl = JLabel; jl.setText('Charge curve fits:')
            jl.setHorizontalAlignment(0)
            str = [commons.getHtmlImage('dcurves_qualitative.png'), ...
                'A charge curve plots the charging voltage against the discharge capacity.<br>', ...
                'There is no demo data available in this release.<br>', ...
                'By default, the discharge curves are used.'];
            jl.setToolTipText(str)
            javacomponent(jl, [], u);
            jb = JButton(b.multiline('Start digitize', 'and fit tool'));
            jb.setToolTipText(b.multiline('Starts a tool for digitizing images and fitting the charge curves.', ...
                'In this release, the discharge curve digitizer tool is used for charge curves.', ...
                'There is no demo data available in this release.', ...
                'By default, the discharge curves are used.'))
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.startCCFitTool;
            %% cccv curve fits
            jl = JLabel; jl.setText('CCCV curve fits:')
            jl.setHorizontalAlignment(0)
            str = [commons.getHtmlImage('cccv_qualitative.png'), ...
                        'A CCCV curve contains 3 curves over the charging time: The current, the voltage and the SoC.<br>', ...
                        'The current and SoC curves are required for the CCCV curve fit in order to generate a function<br>', ...
                        'Imax = f(SoC)'];
            jl.setToolTipText(str)
            javacomponent(jl, [], hc);
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            jb = JButton('Load demo data');
            jb.setToolTipText('Loads a demo CCCV curve fit (maximum current as a function of the SoC).')
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.loadCCCVDemo;
            jb = JButton(b.multiline('Start digitize', 'and fit tool'));
            jb.setToolTipText('Starts a tool for digitizing images and fitting the CCCV charge curves.')
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.startCCCVFitTool;
            %% Age model curve fits
            jl = JLabel; jl.setText('Cycle life curve fits:')
            jl.setHorizontalAlignment(0)
            str = [commons.getHtmlImage('wfit_qualitative.png'), ...
                'A cycle life curve plots the number of cycles to failure against the depth of cycle (DoC).'];
            jl.setToolTipText(str)
            javacomponent(jl, [], hc);
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            jb = JButton('Load demo data');
            jb.setEnabled(0)
            jb.setToolTipText('Loads a demo cycles to failure vs depth of discharge curve fit.')
            javacomponent(jb, [], u);
            b.wfButton{1} = jb;
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.loadACDemo;
            jb = JButton(b.multiline('Start digitize', 'and fit tool'));
            jb.setEnabled(0)
            jb.setToolTipText('Starts a tool for digitizing images and fitting the cycle life curves.')
            b.wfButton{2} = jb;
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.startACFitTool;
            %% Send to workspace button
            jl = JLabel; jl.setText('Build')
            jl.setHorizontalAlignment(0)
            javacomponent(jl, [], hc);
            u = uiflowcontainer('v0', 'parent', hc, 'FlowDirection', 'LeftToRight');
            jb = JButton(b.multiline('Build and', 'send to workspace'));
            jb.setToolTipText('Builds the battery pack and sends it to the workspace.')
            javacomponent(jb, [], u);
            h = handle(jb, 'CallbackProperties');
            h.ActionPerformedCallback = @b.build;
            uu =  uiflowcontainer('v0', 'parent', u, 'FlowDirection', 'TopDown');
            jl = JLabel; jl.setText('Variable name:')
            javacomponent(jl, [], uu);
            jt = JTextPane;
            jt.setText('bat')
            jt.setToolTipText('This must be a valid MATLAB variable name.')
            b.varname = jt;
            h = handle(jt, 'CallbackProperties');
            h.KeyTypedCallback = @b.validMatName;
            javacomponent(jt, [], uu);
            b.f.Visible = 'on';
            end % constructor
            function switchSetup(b, ~, ~)
            if b.jcb1.getSelectedIndex == 1
                b.cpE{3}.setEnabled(false)
                b.cpE{4}.setEnabled(false)
                b.cpE{5}.setEnabled(true)
                b.cpE{6}.setEnabled(true)
                b.calcCV
            else
                b.cpE{3}.setEnabled(true)
                b.cpE{4}.setEnabled(true)
                b.cpE{5}.setEnabled(false)
                b.cpE{6}.setEnabled(false)
                b.calcN
            end
            end % switchSetup
            function ageModelChange(b, src, ~)
                for i = 1:2
                    if src.getSelectedIndex == 0
                        b.wfButton{i}.setEnabled(0)
                    else
                        b.wfButton{i}.setEnabled(1)
                    end
                end
        end
        function calcN(b, ~, ~)
            Cc = str2double(char(b.cpE{1}.getText));
            Vc = str2double(char(b.cpE{2}.getText));
            Cp = str2double(char(b.cpE{3}.getText));
            Vp = str2double(char(b.cpE{4}.getText));
            np = round(Cp ./ Cc);
            ns = round(Vp ./ Vc);
            b.cpE{5}.setText(num2str(np))
            b.cpE{6}.setText(num2str(ns))
        end % calcN
        function calcCV(b, ~, ~)
            Cc = str2double(char(b.cpE{1}.getText));
            Vc = str2double(char(b.cpE{2}.getText));
            np = uint32(str2double(char(b.cpE{5}.getText)));
            ns = uint32(str2double(char(b.cpE{6}.getText)));
            b.cpE{5}.setText(num2str(np))
            b.cpE{6}.setText(num2str(ns))
            Cp = np .* Cc;
            Vp = ns .* Vc;
            b.cpE{3}.setText(num2str(Cp))
            b.cpE{4}.setText(num2str(Vp))
        end % calcCV
        function lim01(b, src, ~) %#ok<INUSL>
            x = str2double(char(src.getText));
            if x > 1
                x = x ./ 10;
            end
            src.setText(num2str(lfpBattery.commons.upperlowerlim(x, 0, 1)))
        end % lim01
        function simplify(b, src, ~)
            if src.isSelected
                b.jcbEQ.removeItemAt(1)
                b.jcbEQ.setEnabled(0)
                b.jcbA.removeItemAt(2)
                for i = 2:4
                    b.Zi{i}.setEnabled(0)
                end
                b.Zi{2}.setText('0')
            else
                b.jcbEQ.addItem('passive')
                b.jcbEQ.setEnabled(1)
                b.jcbA.addItem('cell level')
                if license('test', 'statistics_toolbox')
                    for i = 2:4
                        b.Zi{i}.setEnabled(1)
                    end
                end
            end
        end
        function s = multiline(b, varargin) %#ok<INUSL>
            s = ['<html>', varargin{1}];
            for i = 2:numel(varargin)
                s = [s, '<br>', varargin{i}]; %#ok<AGROW>
            end
            s = [s, '</html>");'];
        end
        function loadDCDemo(b, ~, ~)
            [c, jObj] = b.pauseGUI('Loading data...');
            try
                msg = 'Load demo discharge curve fits?';
                btn = questdlg(msg, ...
                    'Input', ...
                    'OK','Cancel','OK');
                if strcmp(btn, 'OK')
                    [p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
                    load(fullfile(p, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))
                    b.dC = d;
                    jObj.setBusyText('Success!');
                    jObj.stop;
                    pause(1)
                end
            catch ME
                warning(ME.message)
                jObj.setBusyText('Failed!');
                jObj.stop;
                pause(1)
            end
            delete(c)
        end
        function loadCCDemo(b, ~, ~) %#ok<INUSD>
            waitfor(msgbox('No demo data available in this release.', 'error', 'error'))
        end
        function loadCCCVDemo(b, ~, ~)
            [cWait, jObj] = b.pauseGUI('Loading data...');
            try
                msg = 'Load demo CCCV curve fit?';
                btn = questdlg(msg, ...
                    'Input', ...
                    'OK','Cancel','OK');
                if strcmp(btn, 'OK')
                    [p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
                    load(fullfile(p, 'Resources', 'cccvfit.mat'), 'c')
                    b.cC = c;
                    jObj.setBusyText('Success!');
                    jObj.stop;
                    pause(1)
                end
            catch ME
                warning(ME.message)
                jObj.setBusyText('Failed!');
                jObj.stop;
                pause(1)
            end
            delete(cWait)
        end
        function loadACDemo(b, ~, ~)
            import lfpBattery.*
            [c, jObj] = b.pauseGUI('Loading data...');
            try
                msg = 'Load demo cycle life curve fit?';
                btn = questdlg(msg, ...
                    'Input', ...
                    'OK','Cancel','OK');
                if strcmp(btn, 'OK')
                    [p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
                    load(fullfile(p, 'MLUnitTests', 'ageModelTests', 'testInputs.mat'))
                    b.wF = woehlerFit(N, DoDN);
                    jObj.setBusyText('Success!');
                    jObj.stop;
                    pause(1)
                end
            catch ME
                warning(ME.message)
                jObj.setBusyText('Failed!');
                jObj.stop;
                pause(1)
            end
            delete(c)
        end
        function startDCFitTool(b, ~, ~)
            b.dC = b.startCurvefitTool(0, b.dC);
        end
        function startCCFitTool(b, ~, ~)
            b.cC2 = b.startCurvefitTool(0, b.cC2);
        end
        function startCCCVFitTool(b, ~, ~)
            b.cC = b.startCurvefitTool(2, b.cC);
        end
        function startACFitTool(b, ~, ~)
            b.wF = b.startCurvefitTool(1, b.wF);
        end
        function fit = startCurvefitTool(b, index, currFit)
           %0: discharge curves
           %1: woehler curve
           %2: cccv curve
           import lfpBattery.*
           dtool = digitizeTool;
           dtool.externalControl = true;
           dtool.sendbutton.setText('Save data')
           dtool.varname.setText([])
           dtool.varname.setEnabled(0)
           dtool.list.setSelectedIndex(index)
           dtool.list.setEnabled(0)
           dtool.setState
           dtool.mainframe.CloseRequestFcn = 'uiresume; closereq';
           % block current figure
           [c, jObj] = b.pauseGUI('Running curve fit tool...');
           uiwait
           try
               fit = dtool.fit;
               if isempty(fit)
                   error('Cancelled.')
               end
               jObj.setBusyText('Success!');
               jObj.stop;
               pause(1)
           catch ME
               if ~strcmp(ME.message, 'Cancelled.')
                   warning(ME.message)
                   jObj.setBusyText('Failed!')
               else
                   jObj.setBusyText('Cancelled.')
               end
               fit = currFit;
               jObj.stop;
               pause(1)
           end
           delete(c)
        end
        function [c, jObj] = pauseGUI(b, str)
            iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
            iconsSizeEnums = javaMethod('values',iconsClassName);
            SIZE_32x32 = iconsSizeEnums(2);
            jObj = com.mathworks.widgets.BusyAffordance(SIZE_32x32, str);
            jObj.setPaintsWhenStopped(true);
            jObj.useWhiteDots(false);
            [~, c] = javacomponent(jObj.getComponent, [], b.f);
            c.Units = 'normalized';
            pause(0.2)
            c.Position = [0 0 1 1];
            jObj.start;
            pause(0.1)
        end
        function validMatName(b, src, ~) %#ok<INUSL>
            x = char(src.getText);
            if ~isvarname(x)
                src.setText(matlab.lang.makeValidName(x))
            end
        end
        function build(b, ~, ~)
            [c, jObj] = b.pauseGUI('Exporting to workspace...');
            try
                import lfpBattery.*
                b.calcCV; % update pack capacity and voltage
                % extract params
                Cc = str2double(char(b.cpE{1}.getText));
                Vc = str2double(char(b.cpE{2}.getText));
                np = uint32(str2double(char(b.cpE{5}.getText)));
                ns = uint32(str2double(char(b.cpE{6}.getText)));
                aM = char(b.jcbA.getItemAt(b.jcbA.getSelectedIndex));
                if ~strcmp(aM, 'none')
                    if strcmp(aM, 'pack level')
                        aML = 'Pack';
                    else
                        aML = 'Cell';
                    end
                    aM = 'EO';
                else
                    aML = 'Pack'; % default age model level
                end
                EQ = char(b.jcbEQ.getItemAt(b.jcbEQ.getSelectedIndex));
                EQ(1) = upper(EQ(1));
                eta_bc = str2double(char(b.eta{1}.getText));
                eta_bd = str2double(char(b.eta{2}.getText));
                psd = str2double(char(b.psd.getText)); %#ok<PROPLC>
                socIni = str2double(char(b.soc{1}.getText));
                socMin = str2double(char(b.soc{2}.getText));
                socMax = str2double(char(b.soc{3}.getText));
                ideal = b.simple.isSelected;
                sohIni = str2double(char(b.soh.getText));
                topology = char(b.topology.getItemAt(b.topology.getSelectedIndex)); %#ok<PROPLC>
                Zi = str2double(char(b.Zi{1}.getText)); %#ok<PROPLC>
                Zgauss = [0, Zi, Zi]; %#ok<PROPLC>
                if license('test', 'statistics_toolbox')
                    for i = 2:3
                        Zgauss(i-1) = str2double(char(b.Zi{i}.getText));
                    end
                end
                bat = batteryPack(np, ns, Cc, Vc, 'ageModel', aM, 'AgeModelLevel', aML, ...
                    'cycleCounter', 'auto', 'Equalization', EQ, 'etaBC', eta_bc, ...
                    'etaBD', eta_bd, 'ideal', ideal, 'socMax', socMax, 'socMin', socMin, ...
                    'socIni', socIni, 'Topology', topology, 'Zi', Zi, 'Zgauss', Zgauss, ... %#ok<PROPLC>
                    'sohIni', sohIni, 'psd', psd, 'dCurves', b.dC, 'cccvCurves', b.cC, 'cCurve', b.cC2, 'ageCurve', b.wF); %#ok<PROPLC>
                assignin('base', char(b.varname.getText), bat);
                jObj.setBusyText('Success!');
                jObj.stop;
                pause(1)
            catch ME
                warning(ME.message)
                jObj.setBusyText('Failed!');
                jObj.stop;
                pause(1)
            end
            delete(c)
        end
    end
end