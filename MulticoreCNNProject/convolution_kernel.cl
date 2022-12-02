//globalsize : { ic, oc*i*j }
//localsize : { ic, 1 }
__kernel void convolution(__global float *inputs, __global float *filters, __local float *filterout, __global float *outputs, __global float *biases,
	int inputDim, int outputDim, int N) {
	int gi = get_global_id(1);
	int oc = gi / (N * N);	// output channel
	int ic = get_local_id(0);	// input channel && local id
	int j = gi % N;
	int i = (gi - oc * N * N - j) / N;	// global size {[oc][i][j],[ic]}��  ������. ���� oc,i,j�� ���

	float *input = inputs + N * N * ic;
	float *output = outputs + N * N * oc;
	float *filter = filters + 3 * 3 * (oc * inputDim + ic);

	float sum = 0;
	for (int k = 0; k < 3; k++) {
		for (int l = 0; l < 3; l++) {
			int x = i + k - 1;
			int y = j + l - 1;
			if (x >= 0 && x < N && y >= 0 && y < N)
				sum += input[x * N + y] * filter[k * 3 + l];	// filter ����� �� local memory�� ����	
		}
	}

	filterout[ic] = sum;
	barrier(CLK_LOCAL_MEM_FENCE);

	for (int p = get_local_size(0) >> 1; p >= 1; p = p >> 1) {
		if (ic < p) filterout[ic] += filterout[ic + p];
		barrier(CLK_LOCAL_MEM_FENCE);
	}

	if (ic == 0) {
		if (inputDim == 3) filterout[0] += filterout[2];
		filterout[0] += biases[oc];
		output[i * N + j] = (filterout[0] > 0) ? filterout[0] : 0;
	}
}
