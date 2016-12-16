% This is used to convert labels from the NREC Agricultural Person Dataset
% to window files used for training MS-CNN. Requires gt cache file
% generated by evalAll.m

% Based on mscnn_kitti_car_window_file.m, which is downloaded by
% get_kitti_data.sh from https://github.com/zhaoweicai/mscnn
% The license for that original script is a similar non-commercial license
% and is in LICENSE


clear all; close all;

% put the path to the /train/test/val directories of NREC dataset
root_dir = 'path/to/nrec/Dataset';

% choose which data list to generate
 dataType = 'train';
% dataType = 'val';
% dataType = 'test';

% choose a gt cache file to convert from
gtCache = load([dataType,'.mat']);

collected_dir = [root_dir,'/%s/collected/'];
%addpath([root_dir 'devkit_object/devkit/matlab']);
image_dir = sprintf([collected_dir 'ImagesPositiveNegative/'],dataType);
label_dir = sprintf([collected_dir 'AnnotationsPositiveNegative/'],dataType);


id_list = 1:numel(gtCache.gtIndex);

file_name = sprintf('/mnt/trentTop/window_files/mscnn_window_file_usda_%s.txt',dataType);
fid = fopen(file_name, 'wt');

show = 0;
if (show)
  fig = figure(1); set(fig,'Position',[-30 30 960 300]);
  hd.axes = axes('position',[0.1,0.1,0.8,0.8]);
end

for i = 1:length(id_list)
  if (mod(i,500) == 0), fprintf('image idx: %i/%i\n', i, length(id_list)); end
  imgidx = id_list(i);
  img_path = [image_dir gtCache.gtIndex{i} '.png'];
  I=imread(img_path); 
  if (show)
    imshow(I); axis(hd.axes,'image','off'); hold(hd.axes, 'on');
  end
  [imgH, imgW, channels]=size(I);
  
  %objects = readLabels(label_dir, imgidx-1);
  bb = gtCache.gtMats{1}{i};
  if size(bb,1) == 0
      objects = [];
%       objects(1).type = 'DontCare';
%       objects(1).x1 = 1; objects(1).x2 = 479;
%       objects(1).y1 = 1; objects(1).y2 = 719;
%       objects(1).truncation = 0; objects(1).occlusion = 0;
  elseif size(bb,1) == 1
      objects(1).type = 'Pedestrian';
      objects(1).x1 = bb(1); objects(1).x2 = bb(1) + bb(3);
      objects(1).y1 = bb(2); objects(1).y2 = bb(2) + bb(4);
      objects(1).truncation = 0; objects(1).occlusion = bb(5) * 2;
  else
      disp(img_path)
      disp(i)
      error('we have something with another number of labels?)')
  end
  
  fprintf(fid, '# %d\n', i-1);
  fprintf(fid, '%s\n', img_path);
  fprintf(fid, '%d\n%d\n%d\n', channels, imgH, imgW);
  
  labels = []; labelidx = []; dontcareidx = [];
  for j = 1:numel(objects)
    obj = objects(j);
    if (obj.x2<=obj.x1 || obj.y2<=obj.y1)
      continue;
    end
    if (strcmp(obj.type,'Pedestrian'))
      labels = cat(1,labels,1); labelidx = cat(1,labelidx,j); 
    elseif (strcmp(obj.type,'Person_sitting'))
      dontcareidx = cat(1,dontcareidx,j);
    elseif (strcmp(obj.type,'Cyclist'))
      labels = cat(1,labels,2); labelidx = cat(1,labelidx,j); 
    elseif (strcmp(obj.type,'DontCare'))
      dontcareidx = cat(1,dontcareidx,j);
    end
  end
    
  num_objs = length(labelidx);
  fprintf(fid, '%d\n', num_objs);
  for j = 1:num_objs
    idx = labelidx(j); object = objects(idx);
    ignore = 0;
    x1 = object.x1; y1 = object.y1;
    x2 = object.x2; y2 = object.y2;
    w = x2-x1+1; h = y2-y1+1;
    trunc = object.truncation;  occ = object.occlusion; 
    % ignore largely occluded and truncated objects
    if (occ>=2 || trunc>=0.5) 
      ignore = 1;
    end
    fprintf(fid, '%d %d %d %d %d %d\n', labels(j), ignore, round(x1), round(y1), round(x2), round(y2));
    
    if (show)
      if (ignore), color = 'g'; else color = 'r'; end
      rectangle('Position', [x1 y1 w h],'LineWidth',2,'edgecolor',color);   
      text(x1+0.5*w,y1,num2str(labels(j)),'color','r','BackgroundColor','k','HorizontalAlignment',...
         'center','VerticalAlignment','bottom','FontWeight','bold','FontSize',8);
    end
  end
  
  num_dontcare = length(dontcareidx);
  fprintf(fid, '%d\n', num_dontcare);
  for j  = 1:num_dontcare
    idx = dontcareidx(j); object = objects(idx);
    x1 = object.x1; y1 = object.y1;
    x2 = object.x2; y2 = object.y2;
    fprintf(fid, '%d %d %d %d\n', round(x1), round(y1), round(x2), round(y2));
    if (show)
      rectangle('Position', [x1 y1 x2-x1 y2-y1],'LineWidth',2.5,'edgecolor','y');
    end
  end
  if (show), pause(0.01); end
end

fclose(fid);

