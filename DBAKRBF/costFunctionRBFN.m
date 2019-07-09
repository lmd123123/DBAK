function [E, grad] = costFunctionRBFN(parm , y_one_hot , n , Centers , X_train , K , precomputedtw)
% lambda = 0.0001;
% parm : ��Ҫѵ�������в���
% n : ��Ԫ��Ŀ the Number of neurons
% K : ������� �������Ԫ��Ŀ classes
% D : ������ά�� Dimension of the center vector 
% N : ������Ŀ The sample size
% Centers : ��Ԫ���� �� ÿ�б�ʾһ������ n-by-D  the centers of neurons, each row represents a center
% phi : ����ֵ , ÿ�б�ʾһ��������������Ԫ�ļ��� N-by-n+1 Each row represents the activation of all neurons in a sample
% beta : ÿ����Ԫ�ĳ����� n-by-1 the Superparameters of neurons
% alpha : �����Ȩ�أ�ÿ�б�ʾ�������Ԫ����������Ȩ�� K-by-n+1  weight of the output layer
% X_train : ѵ������ ��ÿ�б�ʾһ��ѵ������ N-by-D
% y_score : ÿ������Ԥ��Ϊ��k��ķ��� ��N-by-K
% y_one_hot : ������ǩ one hot ��ʾ , N-by-K
% y : ������ǩ , N-by-1
% E : loss , 1-by-1
% gradAlpha : Alpha �� �ݶ� �� K-by-n+1
% gradBeta : Beta �� �ݶ� �� n-by-1

[N,D] = size(X_train);
alpha = parm(1:(n + 1) * K , :);
alpha = reshape(alpha , K , n + 1);
beta = parm((n + 1) * K + 1:end,:);

% ���㼤��ֵ

[phi,graddist] = RBF_calcAGDTWKernel(X_train , Centers ,beta, precomputedtw);
% nstd = std(phi,[],2);
% nmax = mean(phi,2);
% phi = phi - nmax;
% phi = phi ./ nstd;

% phi = zeros(N, n);
% for i = 1 : N
%     input = X_train(i, :);
%     z = getRBFActivations(Centers, beta, input);
%     phi(i, :) = z';
% end

if max(phi(:)) == inf
    fprintf('phi ���� inf\n');
end
% if max(graddist(:)) == inf
%     fprintf('graddist ���� inf\n');
% end

phi = [ones(N, 1), phi];

% ����y_score
y_score = phi*alpha';
if max(y_score(:)) == inf
    fprintf('y_score ���� inf\n');
end
% ����loss
% E = sum(sum((y_score - y_one_hot).^2));
% E = E / (2 * N);

% ���� softmax
% nmax = mean(y_score,[],1);
% ����������һ��
% nstd = std(y_score,[],1);
% nmax = mean(y_score);
% nmax = max(y_score,[],2);
% y_score = y_score - nmax;
% y_score = bsxfun(@minus,y_score,nmax);
% y_score = y_score ./ nstd;

% ����������һ��
% nstd = std(y_score,[],2);
% nmax = mean(y_score,2);
% y_score = bsxfun(@minus,y_score,nmax);
% y_score = y_score ./ nstd;
% y_score = y_score ./ n;
% y_score = bsxfun(@rdivide,y_score,nstd);
% y_score = y_score ./ mean(y_score,2);
y_score = y_score - max(y_score , [] , 2);
numerator = exp(y_score);
% numerator(numerator > 1e7) = 1e7;
denominator = sum(numerator,2); 
denominator(denominator == 0) = 1;
% y_softmax = bsxfun(@rdivide,numerator,denominator);
y_softmax = numerator ./ denominator;

if max(numerator(:)) == inf
    fprintf('numerator ���� inf\n');
end
if max(denominator(:)) == inf
    fprintf('denominator ���� inf\n');
end
if max(y_softmax(:)) == inf
    fprintf('y_softmax ���� inf\n');
end

% ���� cross entropy
t = y_one_hot;
y = y_softmax;
y = max(min(y,1-eps),eps);
t = max(min(t,1),0);
perfs = -t.*log(y);

lambda = 0;

E = sum(sum(perfs,2)) / N + lambda * sum(sum(alpha(:,2:end) .*alpha(:,2:end))) + lambda * sum(sum(beta .*beta));

if max(y_softmax(:)) == inf
    fprintf('perfs ���� inf\n');
end
if max(E(:)) == inf
    fprintf('E ���� inf\n');
end

% ���� alpha ���ݶ�
normgradalpha = 2 * lambda .* alpha;
normgradalpha(:,1) = 0;
gradAlpha = (y_softmax - y_one_hot)'*phi / N + normgradalpha;
if max(gradAlpha(:)) == inf
    fprintf('gradAlpha ���� inf\n');
end

normgradbeta = 2 * lambda .* beta;
% graddist = -phi(:,2:end) .* (pdist2(X_train , Centers,'euclidean').^2);
gradBeta = sum(((y_softmax - y_one_hot)*alpha(:,2:end)).*graddist,1)'/N + normgradbeta;
if max(gradBeta(:)) == inf
    fprintf('gradBeta ���� inf\n');
end
% gradBeta = zeros(size(gradBeta));
% gradAlpha = zeros(size(gradAlpha));
grad = [reshape(gradAlpha , [] , 1) ; gradBeta];
end
