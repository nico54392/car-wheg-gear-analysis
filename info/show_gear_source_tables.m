%% Display parameter values, equation references, and source PDF locations
% Run this script in MATLAB. All three tabs are read from the paired TXT files.

scriptDir = fileparts(mfilename('fullpath'));
valueFile = fullfile(scriptDir, 'Gear_Parameter_Values_and_Sources.txt');
equationFile = fullfile(scriptDir, 'Gear_Equation_and_Standard_Sources.txt');
if ~isfile(valueFile) || ~isfile(equationFile)
    error('Both source-register TXT files must be beside this script.');
end
[~, valueHeaders, valueRows] = readRegister(valueFile);
[~, equationHeaders, equationRows] = readRegister(equationFile);
sourceLines = readSourceIndex(valueFile);
sourceLines = [sourceLines; {''}; readSourceIndex(equationFile)];

fig = uifigure('Name','Planetary Gear Model | Assumptions & Sources', ...
    'Position',[80 80 1450 820],'Color',[0.965 0.973 0.984]);
root = uigridlayout(fig,[2 1]);
root.RowHeight = {78,'1x'}; root.Padding = [22 16 22 18]; root.RowSpacing = 8;
head = uigridlayout(root,[2 1]); head.RowHeight = {42,26};
head.Padding = [0 0 0 0]; head.RowSpacing = 0;
label = uilabel(head,'Text','Planetary Gear Model', ...
    'FontSize',24,'FontWeight','bold','FontColor',[0.10 0.18 0.29]);
label.Layout.Row = 1;
label = uilabel(head,'Text','Parameter assumptions  |  Equation provenance  |  PDF locations', ...
    'FontSize',13,'FontColor',[0.31 0.39 0.49]);
label.Layout.Row = 2;
tabs = uitabgroup(root,'TabLocation','top');
t1 = uitab(tabs,'Title','Parameter values');
t2 = uitab(tabs,'Title','Equations & standards');
t3 = uitab(tabs,'Title','PDF files & locations');
addTable(t1,valueHeaders,valueRows,[0.15 0.13 0.20 0.52]);
addTable(t2,equationHeaders,equationRows,[0.25 0.30 0.45]);
box = uitextarea(t3,'Value',sourceLines,'Editable','off', ...
    'FontName','Consolas','FontSize',13,'BackgroundColor',[1 1 1], ...
    'FontColor',[0.13 0.18 0.24]);
box.Position = [14 14 1380 710];

function addTable(parent,headers,rows,fractions)
    grid = uigridlayout(parent,[1 1]); grid.Padding = [10 10 10 10];
    t = uitable(grid,'Data',rows,'ColumnName',headers,'RowName',[], ...
        'FontName','Segoe UI','FontSize',12,'ColumnSortable',true);
    t.ColumnWidth = num2cell(max(120,round(1360*fractions)));
end

function [titleText,headers,rows] = readRegister(filePath)
    lines = regexp(fileread(filePath),'\r\n|\n|\r','split');
    titleText = strtrim(lines{1}); %#ok<NASGU>
    mask = cellfun(@(x) ~isempty(regexp(strtrim(x),'^\|','once')),lines);
    tableLines = lines(mask);
    % Drop Markdown separator row (for example |---|---|).
    keep = ~cellfun(@(x) ~isempty(regexp(x,'^\|\s*:?-{3,}','once')),tableLines);
    tableLines = tableLines(keep);
    if numel(tableLines) < 2, error('No complete table found in %s.',filePath); end
    headers = splitPipeRow(tableLines{1});
    rows = cell(numel(tableLines)-1,numel(headers));
    for n = 2:numel(tableLines)
        values = splitPipeRow(tableLines{n});
        if numel(values) ~= numel(headers)
            error('Table row %d has %d columns; expected %d (%s).', ...
                n,numel(values),numel(headers),filePath);
        end
        rows(n-1,:) = values;
    end
end

function values = splitPipeRow(line)
    line = strtrim(line);
    if line(1)=='|', line=line(2:end); end
    if line(end)=='|', line=line(1:end-1); end
    values = strtrim(strsplit(line,'|','CollapseDelimiters',false));
end

function result = readSourceIndex(filePath)
    lines = regexp(fileread(filePath),'\r\n|\n|\r','split');
    start = find(contains(lines,'PDF SOURCE INDEX'),1,'first');
    if isempty(start)
        result = {['No PDF source index in ' filePath]};
    else
        result = lines(start:end).';
    end
end

