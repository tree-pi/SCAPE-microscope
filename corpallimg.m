
% corp all images to exclude unrelated pixels and assume all the signals in 
% corped image come from neurons(not skins/neuropils)

% --to be adapted into a function for pipeline
datap = '/Users/zhiwei/Google Drive/Schoppik Rotation/Data/IZ SC fish2 runA 01-05-17/';
CorpRange =[65,970;240,1740]; % manually set; to throw away skin&other parts of spinocords with no neuron
picArr = 1:1e3;
allcorpim = cell(size(picArr));
existpic = [];
for ipic = picArr
    try
ImMtr = imread([datap,sprintf('fish2 paralyzed 10min after PTZ_0%04d.tif',ipic)]);
    catch
        fprintf('pic%04d unable to import\n',ipic)
        continue
    end
corpIm = ImMtr(CorpRange(1,1):CorpRange(2,1),:);
corpIm = corpIm(:,CorpRange(1,2):CorpRange(2,2));
allcorpim{ipic}=corpIm;
existpic=[existpic,ipic];

% figure;imshow(corpIm,[90,450]);title(ipic) % check if image looks normal

% plot cropped range
%{
h2=figure;
imshow(ImMtr,[90,450])
hold on
[Corpy,Corpx]=meshgrid(CorpRange(:,1),CorpRange(:,2));
plot(Corpx,Corpy,'c-')
hold on
plot(Corpx',Corpy','c-')
saveas(h2,sprintf('kmean_clust/slice_%d_corprange.png',picArr(1)))
%}
end
save('CorpImg','allcorpim','existpic','CorpRange')