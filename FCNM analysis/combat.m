%%combat--Remove site effects,need to add dpabi, spm to the Path
clc,clear
FFileList = 'J:\damage\meta\Gray_matter_volume\literature\4mm_Seeds_Excel\';
FFiles = dir(fullfile(FFileList));
FFiles(2,:) = []; FFiles(1,:) = [];
for i = 1:numel(FFiles)
    FFile{i} = [FFileList FFiles(i).name];
end
MaskData = 'J:\damage\MASK\BrainMask_mm.nii';
sub = readtable('J:\damage\sub.xlsx');  %Demographic information and site for all subjects, listed: SubID, age, sex, SiteName, batch
AdjustInfo.IsCovBat = 0;
AdjustInfo.IsParametric = 1;
AdjustInfo.SiteName = sub.SiteName;
AdjustInfo.batch = sub.batch;
age = sub.age; 
AdjustInfo.mod = [age];
for i = 1:numel(FFiles)
FileList = dir(fullfile(FFile{i},filesep));
FileList = FileList(5).name;
FileLists = [FFile{i} '\' FileList];
File = dir(fullfile(FileLists,filesep,'*.nii'));
Files = {};
for j = 1:numel(File)
Files{j} = [FileLists '\' File(j).name];
end
mkdir([FFile{i},filesep,'zzcombat']);
yw_Harmonization(Files,MaskData,'ComBat/CovBat',AdjustInfo,12,[FFile{i},filesep,'zzcombat']);
end