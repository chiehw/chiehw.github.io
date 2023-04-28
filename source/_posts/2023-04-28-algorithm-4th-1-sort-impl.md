---
title: 《算法 第4版》-排序算法实现
date: 2023-04-28 19:35:27
categories: 算法
---
本文选用 LeetCode 中的 [912. 排序数组](https://leetcode.cn/problems/sort-an-array/) 作为练习题。

![十大经典排序算法.png](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/04/upgit_20230425_1682411440.png)

# 01 选择排序 - 超时

```c++
class Solution {
public:
    vector<int> sortArray(vector<int>& nums) {
        int n = nums.size();
        int minIndex;
        for(int i=0; i<n-1; ++i){
            minIndex = i;
            for(int j=i+1; j<n; ++j){
                if(nums[j] < nums[minIndex]){
                    minIndex = j;
                }
            }
            swap(nums[i], nums[minIndex]);
        }
        return nums;
    }
};
```

# 02 插入排序 - 超时

```c++
class Solution {
public:
    vector<int> sortArray(vector<int>& nums) {
        int n = nums.size();
        for(int i=1; i<n; i++){
            for(int j=i; j>0 && nums[j]<nums[j-1]; j--){
                swap(nums[j], nums[j-1]);
            }
        }
        return nums;
    }
};
```

# 03 希尔排序

```c++
class Solution {
public:
    vector<int> sortArray(vector<int>& nums) {
        int N = nums.size();
        int h=1;
        while(h<N/3) h=3*h+1;
        while(h>=1){
            for(int i=h; i<N; i++){
                for(int j=i; j>=h && nums[j]<nums[j-h]; j-=h){
                    swap(nums[j], nums[j-h]);
                }
            }
            h=h/3;
        }
        return nums;
    }
};
```

# 04 归并-自上而下

```c++
class Solution {
private:
    vector<int> tmp;
    void merge(vector<int>& nums, int lo, int mid, int hi){
        int N = nums.size();
        int i=lo, j=mid+1;
        for(int k=lo; k<=hi; k++)
            tmp[k] = nums[k];
        for(int k=lo; k<=hi; k++){
            if(i>mid)                   nums[k] = tmp[j++];
            else if(j>hi)               nums[k] = tmp[i++];
            else if(tmp[j]<tmp[i])      nums[k] = tmp[j++];
            else                        nums[k] = tmp[i++];
        }
    }

    void mergeSort(vector<int>& nums, int lo, int hi){
        if(hi <= lo) return;
        int mid = lo + (hi-lo)/2;
        mergeSort(nums, lo, mid);
        mergeSort(nums, mid+1, hi);
        merge(nums, lo, mid, hi);
    }
public:
    vector<int> sortArray(vector<int>& nums) {
        tmp = nums;
        mergeSort(nums, 0, nums.size()-1);
        return nums;
    }
};
```

# 05 归并-自下而上

```c++
class Solution {
private:
    vector<int> tmp;
    void merge(vector<int> &nums, int lo, int mid, int hi){
        int N = nums.size();
        int i=lo, j=mid+1;
        for(int k=lo; k<=hi; k++)
            tmp[k] = nums[k];
        for(int k=lo; k<=hi; k++){
            if(i>mid)               nums[k] = tmp[j++];
            else if(j>hi)           nums[k] = tmp[i++];
            else if(tmp[j]<tmp[i])  nums[k] = tmp[j++];
            else                    nums[k] = tmp[i++];
        }
    }

public:
    vector<int> sortArray(vector<int>& nums) {
        int N = nums.size();
        tmp = nums;
        for(int size=1; size<N; size=size*2){
            for(int lo=0; lo<N-size; lo += size*2){
                merge(nums, lo, lo+size-1, min(lo+size*2-1, N-1));
            }
        }
        return nums;
    }
};
```

# 06 快速排序

```c++
class Solution {
private:
    int partition(vector<int> &nums,int lo, int hi){
        int i=lo, j=hi+1;
        int v = nums[lo];
        while(true){
            while(nums[++i] < v) if(i==hi) break;
            while(v < nums[--j])     if(j==lo) break;
            if(i>=j) break;
            swap(nums[i], nums[j]);
        }
        swap(nums[lo], nums[j]);
        return j;
    }
    void sort(vector<int> &nums, int lo, int hi){
        if(hi <= lo) return;
        int j=partition(nums, lo, hi);
        sort(nums, lo, j-1);
        sort(nums, j+1, hi);
    }
public:
    vector<int> sortArray(vector<int>& nums) {
        auto rng = default_random_engine {};
        shuffle(begin(nums), end(nums), rng);
        sort(nums, 0, nums.size() - 1);
        return nums;
    }
};
```

# 07 堆排序 

```c++
class Solution {
private:
    void sink(vector<int> &nums, int k, int N){
        while(2*k <= N){
            int j = 2*k;
            if(j<N && nums[j+1]>nums[j])    j++;
            if(nums[k]>nums[j])             break;
            swap(nums[k], nums[j]);
            k = j;
        }
    }
public:
    vector<int> sortArray(vector<int>& nums) {
        int N = nums.size();
        nums.insert(nums.begin(), 0);
        
        for(int k=N/2;k>=1; k--){
            sink(nums, k, N);
        }
        while(N>1){
            swap(nums[1], nums[N--]);
            sink(nums, 1, N);
        }
       
        nums.erase(nums.begin()); 
        return nums;
    }
};
```

# 08 计数排序

```c++
class Solution {
private:
    vector<int> aux;
public:
    vector<int> sortArray(vector<int>& nums) {
        int N = nums.size();

        int minNum = INT_MAX, maxNum = INT_MIN;
        for (int i = 0; i < N; ++i) {
            if (nums[i] < minNum) minNum = nums[i];
            if (nums[i] > maxNum) maxNum = nums[i];
        }

        int R =  maxNum - minNum + 1;
        vector<int> counts(1 + R, 0);
        // 1. count
        for (int i=0; i<N; ++i) {
            counts[(nums[i] - minNum)+1]++;
        }
        
        // 2. count to index
        for(int r=0; r<R; r++){
            counts[r+1] += counts[r];
        }

        // 3. sort
        aux = nums;
        for (int i=0; i<N; ++i) {
            aux[counts[nums[i]-minNum]++] = nums[i];
        }
        
        // 4. rewrite
        for (int i=0; i<N; ++i) {
            nums[i] = aux[i];
        }
        return nums;
    }
};
```

