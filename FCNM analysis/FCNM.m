%% Step 1. Add spm12, dpabi and the ROI_ball_gen.m (used to draw the ball) to the path
clear,clc

%% Step 2. Read the basic information and header for each individual study
% downloaded all the PDF documents included in the study, each document recommended structure for P + number + author + year of publication
% If you do not download all the PDF documents, the missing documents can be manually created by yourself to create a random PDF file, we just need to read the basic information and header of each document here!

path = 'J:\damage\meta\Gray_matter_volume\literature';%Path to the main folder   Gray_matter_volume\Resting_state_activity\Task_induced_activation 
mkdir([path,filesep,'Articles_Included']);%Create Articles_Included folder and place the PDFs of all the included studies in it
Articles_path = [path,filesep,'Articles_Included'];
File = dir(fullfile(Articles_path,'*.pdf'));%Read all PDF files of Articles_Included
Filename ={File.name};
[~,col]=size(Filename);
%% Step 3. Create an Excel table with the coordinates of all the articles, and then manually fill in the corresponding table with the coordinates of all the articles.

mkdir([path,filesep,'Articles_Included_Excel']);%Create Articles_Included_Excel folder
cd([path,filesep,'Articles_Included_Excel']);

for i = 1:col% In the Excel document in column D, if there are more than one ROI results can be form down to auto-fill
    filename=char(Filename(i));
    xlswrite([filename(1:end-4),'.xlsx'],cellstr([filename(1:end-4),'_ROI01']),'sheet1','D1')
end

%% Step 4. Generate spheres based on the ROI of each study and merge spheres from the same study

[row,col]=size(Filename);
for i = 1:col
    filename=char(Filename(i));
    radius_Seeds_Excel = [path,'\4mm_Seeds_Excel\'];
    mkdir([ radius_Seeds_Excel, filename(1:end-4)])% Create the folders needed for each article
    cd ([radius_Seeds_Excel, filename(1:end-4)]);
    mkdir ROI_Seeds
    mkdir(['onesample_',filename(1:end-4)])
    mkdir(['zFC_',filename(1:end-4)])
    % Draw individual ROI 
    [coord, ROIs]=xlsread([path,filesep,'Articles_Included_Excel',filesep,filename(1:end-4),'.xlsx']);%Read the coordinates of the excel file
    Reference_image_path = 'J:\damage\MASK';%the resolution of mask file should be the same as the resolution of all the analyzed images.
    ROI_ball_gen(coord,ROIs,[Reference_image_path,filesep,'BrainMask_mm.nii'],4); %BrainMask_mm.nii is the image required for defining the ROI resolution; 4 is the radius of the sphere defined as 4mm;
  
    % Combine the ROI from each study into large mask
    Combine_file={};
    for j = 1:length(ROIs)
        combine_file = [radius_Seeds_Excel,filename(1:end-4),'\',filename(1:end-4),'_ROI',num2str(j,'%02d'),'.nii,1'];
        Combine_file=[Combine_file;{combine_file}];
    end
    Combine_ROI=[];
    for k = 1:length(ROIs)
        combine_ROI=['i',int2str(k)];
        Combine_ROI=[Combine_ROI,'+',combine_ROI];
        Combine_ROIs=Combine_ROI(2:end);
    end
    
    jobs{1}.spm.util.imcalc.input = Combine_file;
    jobs{1}.spm.util.imcalc.output = [filename(1:end-4),'_Seeds'];
    jobs{1}.spm.util.imcalc.outdir = {[radius_Seeds_Excel,filename(1:end-4),'\ROI_Seeds']};
    jobs{1}.spm.util.imcalc.expression = Combine_ROIs;
    jobs{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    jobs{1}.spm.util.imcalc.options.dmtx = 0;
    jobs{1}.spm.util.imcalc.options.mask = 0;
    jobs{1}.spm.util.imcalc.options.interp = 1;
    jobs{1}.spm.util.imcalc.options.dtype = 4;
    spm('defaults', 'FMRI')
    spm_jobman('run', jobs)
    clear jobs
end

%% Step 5 Calculate functional connectivity (FC) with dpabi
working_directory = 'J:\damage\station\BMB';%Location of the total folder for all subjects
%Need to set a parameter file manually by yourself with the dpabi software
load([working_directory,filesep,'dpabi_FC_parameters.mat']);
for i = 1:col
    filename=char(Filename(i));
    Cfg.CalFC.ROIDef{1,1}=[radius_Seeds_Excel,filename(1:end-4),'\ROI_Seeds\',filename(1:end-4),'_Seeds.nii'];
    
    AutoDataProcessParameter = Cfg;
    WorkingDir = [];
    SubjectListFile = [];
    IsAllowGUI= [];
    [Error, AutoDataProcessParameter]=DPARSFA_run(AutoDataProcessParameter,WorkingDir,SubjectListFile,IsAllowGUI);%Calculate FC with dpabi
    
    file = dir([working_directory,filesep,'Results\','FC_',Cfg.StartingDirName,filesep,'zFC*']);
    
  for j = 1:length(file)
      movefile([working_directory,filesep,'Results\','FC_',Cfg.StartingDirName,filesep,file(j).name],...
       [radius_Seeds_Excel,filename(1:end-4),'\zFC_',filename(1:end-4)]);
  end
   rmdir([working_directory,filesep,'Masks'],'s');
   rmdir([working_directory,filesep,'Results'],'s');
   movefile([radius_Seeds_Excel,filename(1:end-4),'\P*'],[radius_Seeds_Excel,filename(1:end-4),'\ROI_Seeds'])
   
%one-sample t-test
%Till_spmT_0001
    filename=char(Filename(i));
    zFC_namelist = dir([radius_Seeds_Excel,filename(1:end-4),'\zFC_',filename(1:end-4),'\zFC*']);
    len = length(zFC_namelist);
    for j = 1:len
        file_name{j} = [radius_Seeds_Excel,filename(1:end-4),'\zFC_',filename(1:end-4),'\',zFC_namelist(j).name];
    end
    File_name = file_name(1:end)';
  %-----------------------------------------------------------------------  
  %Factorial design specification
  jobs{1}.spm.stats.factorial_design.dir = {[radius_Seeds_Excel,filename(1:end-4),'\onesample_',filename(1:end-4)]};
  jobs{1}.spm.stats.factorial_design.des.t1.scans = File_name;
  jobs{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
  jobs{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
  jobs{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
  jobs{1}.spm.stats.factorial_design.masking.im = 1;
  jobs{1}.spm.stats.factorial_design.masking.em = {'J:\damage\MASK\BrainMask.nii,1'};%Path to mask
  jobs{1}.spm.stats.factorial_design.globalc.g_omit = 1;
  jobs{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
  jobs{1}.spm.stats.factorial_design.globalm.glonorm = 1;
  
  spm('defaults', 'FMRI');
  spm_jobman('run', jobs);
  clear jobs
  
  
  jobs{1}.spm.stats.fmri_est.spmmat = {[radius_Seeds_Excel,filename(1:end-4),'\onesample_',filename(1:end-4),'\SPM.mat']};
  jobs{1}.spm.stats.fmri_est.write_residuals = 0;
  jobs{1}.spm.stats.fmri_est.method.Classical = 1;
  
  spm('defaults', 'FMRI');
  spm_jobman('run', jobs);
  clear jobs
  %Model estimation
  
  jobs{1}.spm.stats.con.spmmat = {[radius_Seeds_Excel,filename(1:end-4),'\onesample_',filename(1:end-4),'\SPM.mat']};
  jobs{1}.spm.stats.con.consess{1}.tcon.name = 'onesample';
  jobs{1}.spm.stats.con.consess{1}.tcon.weights = 1;
  jobs{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
  jobs{1}.spm.stats.con.delete = 0;
  
  spm('defaults', 'FMRI');
  spm_jobman('run', jobs);
  clear jobs
end

