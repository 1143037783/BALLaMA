[solvable_queries](..%2Ftmp%2Fenv%2Fsolvable_queries)# BALLaMA: Learning the Boundary Between Internal and External Tools for Large Language Models

[![Project](assets/icons/Project-BALLaMA-blue.svg)](https://github.com/1143037783/stableToolBench)
[![Paper](assets/icons/Paper-ArXiv-red.svg)](https://arxiv.org/)
[![License](assets/icons/License-Apache_2.0-blue.svg)](LICENSE)

**BALLaMA** is a framework built upon [StableToolBench](https://github.com/OpenBMB/ToolBench) that enables adaptive tool usage in Large Language Models (LLMs) by learning the boundary between internal parametric knowledge and external API calls.

## Main Contributions

This work makes two key contributions:

1. **Internal Tool Construction**: We encapsulate the model's implicit parametric knowledge into standardized **internal tools** that maintain one-to-one mapping with external APIs, creating a unified action space for seamless resource orchestration.

2. **Boundary-Aware Model Training**: We develop a two-stage training paradigm (SFT + DPO) that enables LLMs to adaptively select between internal and external tools based on task context, overcoming calibration biases and over-reliance on external APIs.

## Environment Setup

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Download Tools
The training datasets include:
- **toolenv**: 功能执行环境

  注：所有的内部工具默认使用**deepseek**模型，请在`env/toolenv/tools/client.py`中配置相关参数

- **training_data**: Hybrid trajectories with mixed internal/external tool usage

Download from: [Google Driver](https://drive.google.com/file/d/1IaCS5C_N-ezktMBlsa29OzgxiGh2nIHJ/view?usp=drive_link)

## Model Download

Pre-trained BALLaMA models are available on HuggingFace:

- **Base Models**: [meta-llama/Llama-2-7b-hf](https://huggingface.co/meta-llama/Llama-2-7b-hf/tree/main)
- **LoRA Models**: [Arno-vc/BALLaMA · Hugging Face](https://huggingface.co/Arno-vc/BALLaMA)

## Running Scripts

### 1. Model Training

推荐基于[LlamaFactory](https://github.com/hiyouga/LlamaFactory)的训练配置：

* 基于[ToolBench](https://github.com/OpenBMB/ToolBench/tree/master/toolbench)的SFT训练效果更好，但是速度更慢
* 对于LoRA微调，DPO的lora_rank应该比SFT的lora_rank更高，这样可以进行更精细地调整

### 2. Model Inference

* 使用Deepseek API

  * **With External Tools Only:**

    ```sh
    export TOOLBENCH_KEY=""
    export RAPIDAPI_KEY=""
    export OPENAI_KEY=""
    export OPENAI_API_BASE=""
    export PYTHONPATH=./
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    
    export GPT_MODEL=""
    
    export TOOL_TYPE=tool
    export OUTPUT_DIR="data/Deepseek/${TOOL_TYPE}/answer/virtual_chatgpt_dfs"
    
    GROUP_LIST=(
      G1_instruction
      G1_category
      G1_tool
      G2_category
      G2_instruction
      G3_instruction
    )
    
    for group in "${GROUP_LIST[@]}"; do
        echo "===== Running group: $group ====="
    
        mkdir -p $OUTPUT_DIR; mkdir -p $OUTPUT_DIR/$group
    
        python toolbench/inference/qa_pipeline_multithread.py \
            --tool_root_dir toolenv/tools \
            --backbone_model chatgpt_function \
            --chatgpt_model $GPT_MODEL \
            --openai_key $OPENAI_KEY \
            --max_observation_length 1024 \
            --method DFS_woFilter_w2 \
            --input_query_file solvable_queries/test_instruction/${group}.json \
            --output_answer_file $OUTPUT_DIR/$group \
            --rapidapi_key $RAPIDAPI_KEY \
            --toolbench_key $TOOLBENCH_KEY \
            --base_url $OPENAI_API_BASE > ${OUTPUT_DIR}/${group}/run.log 2>&1 \
            --single_chain_max_step 12
    done
    ```

  * **With Mixed Tools (Internal + External):**

    ```sh
    export TOOLBENCH_KEY=""
    
    export OPENAI_KEY=""
    export OPENAI_API_BASE=""
    export PYTHONPATH=./
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    
    export GPT_MODEL=""
    
    export TOOL_TYPE=LLM_tool
    export OUTPUT_DIR="data/Deepseek/${TOOL_TYPE}/answer/virtual_chatgpt_dfs"
    
    GROUP_LIST_LLM_tool=(
      G1_instruction_LLM_tool
      G1_category_LLM_tool
      G1_tool_LLM_tool
      G2_category_LLM_tool
      G2_instruction_LLM_tool
      G3_instruction_LLM_tool
    )
    
    for group in "${GROUP_LIST_LLM_tool[@]}"; do
        echo "===== Running group: $group ====="
    
        mkdir -p $OUTPUT_DIR; mkdir -p $OUTPUT_DIR/$group
    
        python toolbench/inference/qa_pipeline_multithread.py \
            --tool_root_dir toolenv/tools \
            --backbone_model chatgpt_function \
            --chatgpt_model $GPT_MODEL \
            --openai_key $OPENAI_KEY \
            --max_observation_length 1024 \
            --method DFS_woFilter_w2 \
            --input_query_file solvable_queries/test_instruction/${group}.json \
            --output_answer_file $OUTPUT_DIR/$group \
            --rapidapi_key $RAPIDAPI_KEY \
            --toolbench_key $TOOLBENCH_KEY \
            --base_url $OPENAI_API_BASE > ${OUTPUT_DIR}/${group}/run.log 2>&1 \
            --single_chain_max_step 12
    done
    ```

* 使用BALLaMA

  * **With External Tools Only:**

    ```sh
    export TOOLBENCH_KEY=""
    
    export OPENAI_KEY=""
    export OPENAI_API_BASE=""
    export PYTHONPATH=./
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    
    export GPT_MODEL=""
    
    export OUTPUT_DIR="data/LLM_tool/answer/virtual_chatgpt_dfs"
    
    GROUP_LIST=(
      G1_category
      G1_instruction
      G1_tool
      G2_category
      G2_instruction
    )
    
    for group in "${GROUP_LIST[@]}"; do
        echo "===== Running group: $group ====="
    
        mkdir -p $OUTPUT_DIR; mkdir -p $OUTPUT_DIR/$group
    
        python toolbench/inference/qa_pipeline.py \
            --tool_root_dir toolenv/tools \
            --backbone_model toolllama \
            --model_path model/LLaMA-2-7b \
            --lora model/BALLaMA \
            --openai_key $OPENAI_KEY \
            --max_observation_length 1024 \
            --observ_compress_method truncate \
            --method DFS_woFilter_w2 \
            --input_query_file solvable_queries/test_instruction/${group}.json \
            --output_answer_file $OUTPUT_DIR/$group \
            --toolbench_key $TOOLBENCH_KEY \
            --base_url $OPENAI_API_BASE > ${OUTPUT_DIR}/${group}/run.log 2>&1
    done
    ```

  * **With Mixed Tools (Internal + External):**

    ```sh
    export TOOLBENCH_KEY=""
    
    export OPENAI_KEY=""
    export OPENAI_API_BASE=""
    export PYTHONPATH=./
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    
    export GPT_MODEL=""
    
    export OUTPUT_DIR="data/LLM_tool/answer/virtual_chatgpt_dfs"
    
    GROUP_LIST_LLM_tool=(
      G1_instruction_LLM_tool
      G1_tool_LLM_tool
      G1_category_LLM_tool
      G2_instruction_LLM_tool
      G2_category_LLM_tool
      G3_instruction_LLM_tool
    )
    
    for group in "${GROUP_LIST_LLM_tool[@]}"; do
        echo "===== Running group: $group ====="
    
        mkdir -p $OUTPUT_DIR; mkdir -p $OUTPUT_DIR/$group
    
        python toolbench/inference/qa_pipeline.py \
            --tool_root_dir toolenv/tools \
            --backbone_model toolllama \
            --model_path model/LLaMA-2-7b \
            --lora model/BALLaMA \
            --openai_key $OPENAI_KEY \
            --max_observation_length 1024 \
            --observ_compress_method truncate \
            --method DFS_woFilter_w2 \
            --input_query_file solvable_queries/test_instruction/${group}.json \
            --output_answer_file $OUTPUT_DIR/$group \
            --toolbench_key $TOOLBENCH_KEY \
            --base_url $OPENAI_API_BASE > ${OUTPUT_DIR}/${group}/run.log 2>&1
    done
    ```

注：

* TOOLBENCH_KEY需要向**[StableToolBench](https://github.com/THUNLP-MT/StableToolBench/tree/master)**申请
* 将DFSDT范式修改为ReAct：将`method`参数修改为`CoT@1`即可

### 4. Evaluation
* convert：使用`toolbench/tooleval/convert.sh`转换答案格式

* evaluation：使用`toolbench/tooleval/evaluation.sh`进行评估

  注：需要在`openai_key.json`中配置模型

## Results

1. ReACT范式：在`single_chain_max_step=12`的情况下SoPR几乎都为0，因此将`single_chain_max_step=50`

   | Model                             |  I1-Ins.  |  I1-Cat.  | I1-Tool.  |  I2-Cat.  |  I2-Ins.  |  I3-Ins.  |    avg    |
   | :-------------------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :-------: | :-------: |
   | Deepseek+External Tool            |   32.3%   |   51.1%   |   38.1%   |   37.4%   |   15.1%   |   23.0%   |   32.8%   |
   | Deepseek+Mix Tool                 | **39.9%** | **54.0%** | **47.0%** | **39.2%** | **30.8%** | **30.6%** | **40.3%** |
   | Qwen+External Tool                |   26.8%   |   38.8%   |   25.7%   |   26.3%   |   15.1%   |   14.8%   |   24.6%   |
   | Qwen+Mix Tool                     |   29.8%   |   37.6%   |   27.1%   |   29.0%   |   18.9%   |   18.0%   |   26.7%   |
   | ToolLLaMA-1-7b-v1 + External Tool |   7.8%    |   17.0%   |   8.6%    |   7.5%    |   1.3%    |   0.0%    |   7.0%    |
   | ToolLLaMA-1-7b-v1 + Mix Tool      |   7.8%    |   20.0%   |   9.2%    |   9.1%    |   5.1%    |   0.0%    |   8.5%    |
   | ToolLLaMA-2-7b-v2 + External Tool |   18.6%   |   22.5%   |   16.6%   |   12.6%   |   16.0%   |   0.6%    |   14.5%   |
   | ToolLLaMA-2-7b-v2 + Mix Tool      |   19.2%   |   22.9%   |   19.2%   |   12.4%   |   10.4%   |   0.0%    |   14.0%   |
   | BaLLaMA+External Tool             |   22.9%   |   28.5%   |   23.2%   |    18%    |   13.8%   |   3.9%    |   18.4%   |
   | BaLLaMA+Mix Tool                  |   23.2%   |   37.3%   |   21.1%   |   21.2%   |   20.8%   |   18.6%   |   23.7%   |

2. DFSDT范式：`single_chain_max_step=12`

   | Model                             |  I1-Ins.  |  I1-Cat.  | I1-Tool.  |  I2-Cat.  |  I2-Ins.  | I3-Ins.  |    avg    |
   | :-------------------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------: | :-------: |
   | Deepseek+External Tool            |   32.3%   |   42.0%   |   32.9%   |   32.8%   |   19.2%   |   0.6%   |   26.6%   |
   | Deepseek+Mix Tool                 | **37.0%** | **43.2%** | **37.1%** | **32.0%** | **27.0%** | **7.8%** | **30.7%** |
   | Qwen+External Tool                |   28.2%   |   32.7%   |   20.6%   |   24.5%   |   12.9%   |   1.6%   |  20.08%   |
   | Qwen+Mix Tool                     |   34.8%   |    42%    |   38.2%   |   27.7%   |   22.6%   |   18%    |  30.55%   |
   | ToolLLaMA-2-7b-v1 + External Tool |    9%     |   16.9%   |   7.9%    |   8.4%    |   2.1%    |    0%    |   7.38%   |
   | ToolLLaMA-2-7b-v1 + Mix Tool      |   7.2%    |   12.4%   |    9%     |   9.9%    |   5.2%    |    0%    |   7.28%   |
   | ToolLLaMA-2-7b-v2 + External Tool |   18.9%   |   30.3%   |   21.4%   |   13.2%   |   18.2%   |   3.3%   |  17.55%   |
   | ToolLLaMA-2-7b-v2 + Mix Tool      |   20.7%   |   32.2%   |   19.9%   |   11.4%   |   13.3%   |   3.5%   |  16.83%   |
   | BaLLaMA+External Tool             |   20.5%   |    32%    |   19.7%   |   16.5%   |    11%    |   3.3%   |  17.17%   |
   | BaLLaMA+Mix Tool                  |   24.9%   |   33.3%   |   21.7%   |   18.0%   |   13.7%   |   7.7%   |  19.88%   |

## License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.