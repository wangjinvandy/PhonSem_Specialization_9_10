%% First level analysis, more contrasts, written by Jin Wang 3/15/2019
% All you need to do with this code is to comment out the lines from 97 to
% 155 from a typical firstlevel code (e.g. firstlevel_generate_bids_ELP.m). 
% Then you can specify the new contrast you want. It will call
% more_contrast.m code which will add on or repalce your previous contrasts.
% This code can save you a lot of time of model specification and
% estimation.

%%%Do you want to rewrite your contrasts or add on new contrasts?
type=0; %1 is rewrite, 0 is append on. 

addpath(genpath('/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/SemPhon_9_10/scripts/3firstlevel')); % the path of your scripts
spm_path='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/LabCode/typical_data_analysis/spm12_elp'; %the path of spm
addpath(genpath(spm_path));

%define your data path
data=struct();
root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/SemPhon_9_10';  %your project path
subjects={};
data_info='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/SemPhon_9_10/data_info.xlsx';
if isempty(subjects)
    M=readtable(data_info);
    subjects=M.participant_id;
end

analysis_folder='analysis'; % the name of your first level modeling folder
model_deweight='deweight'; % the deweigthed modeling folder, it will be inside of your analysis folder
global CCN
CCN.preprocessed='preprocessed'; % your data folder
CCN.session='ses-9'; % the time points you want to analyze
CCN.func_pattern='sub*'; % the name of your functional folders
CCN.file='vs6_wsub*bold.nii'; % the name of your preprocessed data (4d)
CCN.rpfile='rp_*.txt'; %the movement files

%define your contrasts, make sure your contrasts and your weights should be
%matched.
contrasts={'Onset_vs_Rhyme_VS_Low_vs_High'};
Onset_vs_Rhyme=[0 1 -1 0];
Low_vs_High=[0 -1 1 0];

%adjust the contrast by adding six 0s into the end of each session
rp_w=zeros(1,6);
empty=zeros(1,10);
weights={[Onset_vs_Rhyme rp_w Onset_vs_Rhyme rp_w -1*Low_vs_High rp_w -1*Low_vs_High rp_w]};

%%%%%%%%%%%%%%%%%%%%%%%%Do not edit below here%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check if you define your contrasts in a correct way
if length(weights)~=length(contrasts)
    error('the contrasts and the weights are not matched');
end      

% Initialize
%addpath(spm_path);
spm('defaults','fmri');
spm_jobman('initcfg');
spm_figure('Create','Graphics','Graphics');

% Dependency and sanity checks
if verLessThan('matlab','R2013a')
    error('Matlab version is %s but R2013a or higher is required',version)
end

req_spm_ver = 'SPM12 (6225)';
spm_ver = spm('version');
if ~strcmp( spm_ver,req_spm_ver )
    error('SPM version is %s but %s is required',spm_ver,req_spm_ver)
end

%Start to analyze the data from here
try
    for i=1:length(subjects)
        fprintf('work on subject %s', subjects{i});
        CCN.subject=[root '/' CCN.preprocessed '/' subjects{i}];
        %specify the outpath,create one if it does not exist
        out_path=[CCN.subject '/' analysis_folder];
        if ~exist(out_path)
            mkdir(out_path)
        end
         
        %specify the deweighting spm folder, create one if it does not exist
        model_deweight_path=[out_path '/' model_deweight];
        if exist(model_deweight_path,'dir')~=7
            mkdir(model_deweight_path)
        end
        
%         %find folders in func
%         CCN.functional_dirs='[subject]/[session]/func/[func_pattern]/';
%         functional_dirs=expand_path(CCN.functional_dirs);
%         
%         %re-arrange functional_dirs so that run-01 is always before run-02
%         %if they are the same task. This is only for ELP project.
%         func_dirs_rr=functional_dirs;
%         for rr=1:length(functional_dirs)
%             if rr<length(functional_dirs)
%             [~, taskrunname1]=fileparts(fileparts(functional_dirs{rr}));
%             taskname1=taskrunname1(21:25);
%             taskrun1=str2double(taskrunname1(end-5:end-5));
%             [~, taskrunname2]=fileparts(fileparts(functional_dirs{rr+1}));
%             taskname2=taskrunname2(21:25);
%             taskrun2=str2double(taskrunname2(end-5:end-5));
%             if strcmp(taskname1,taskname2) && taskrun1>taskrun2
%                 func_dirs_rr{rr}=functional_dirs{rr+1};
%                 func_dirs_rr{rr+1}=functional_dirs{rr};
%             end
%             end
%         end
%                 
%         %load the functional data, 6 mv parameters, and event onsets
%         mv=[];
%         swfunc=[];
%         P=[];
%         onsets=[];
%         for j=1:length(func_dirs_rr)
%              swfunc{j}=expand_path([func_dirs_rr{j} '[file]']);
%             %load the event onsets
%             if events_file_exist==1
%                 [p,run_n]=fileparts(func_dirs_rr{j}(1:end-1));
%                 event_file=[func_dirs_rr{j} run_n(1:end-4) 'events.tsv'];
%             elseif events_file_exist==0
%                 [p,run_n]=fileparts(func_dirs_rr{j}(1:end-1));
%                 [q,session]=fileparts(fileparts(p));
%                 [~,this_subject]=fileparts(q);
%                 event_file=[bids_folder '/' this_subject '/' session '/func/' run_n(1:end-4) 'events.tsv'];
%                 rp_file=[p '/' run_n '/rp_' run_n '_0001.txt'];
%             end
%             event_data=tdfread(event_file);
%             cond=unique(event_data.trial_type,'row');
%             [~,len]=size(cond);
%             for k=1:size(cond,1)
%             onsets{j}{k}=event_data.onset(sum((event_data.trial_type==cond(k,:))')'==len);
%             end
%             mv{j}=load(rp_file); 
%         end
%         data.swfunc=swfunc;
%         
%         
%         %pass the experimental design information to data
%         data.conditions=conditions;
%         data.onsets=onsets;
%         data.dur=dur;
%         data.mv=mv;
%         
%         %run the firstlevel modeling and estimation (with deweighting)
%         mat=firstlevel_4d(data, out_path, TR, model_deweight_path);
        mat=[model_deweight_path,'/SPM.mat'];
        origmat=[out_path '/SPM.mat'];
        %run the contrasts
        more_contrast(origmat,contrasts,weights, type);
        more_contrast(mat,contrasts,weights, type);
        
    end
    
catch e
    rethrow(e)
    %display the errors
end