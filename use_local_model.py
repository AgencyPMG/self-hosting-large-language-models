#!/usr/bin/env python
"""
Small script to show an example of using a local model
"""

import argparse
import pprint
import typing
import pathlib
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline

ModelResult = typing.Tuple[AutoModelForCausalLM, AutoTokenizer]

def load_model(model_path: pathlib.Path):
    """
    Could drop this into a notebook to download the model in a specific
    environment (eg AWS sagemaker with inferentia)
    """
    assert model_path.exists()

    tokenizer = AutoTokenizer.from_pretrained(str(model_path))
    model = AutoModelForCausalLM.from_pretrained(str(model_path))

    return (tokenizer, model,)

def prompt(model_path: pathlib.Path, prompt: str):
    tokenizer, model = load_model(model_path)

    p = pipeline('text-generation', model=model, tokenizer=tokenizer)
    return p(prompt)


ArgsType = typing.Optional[typing.List[str]]

def parse_args(args: ArgsType=None) -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument('model_path', type=pathlib.Path, help='which model to use')
    p.add_argument('prompt', help='the prompt to submit')

    return p.parse_args(args)

def main(args: ArgsType=None):
    args = parse_args(args)

    pprint.pprint(prompt(args.model_path, args.prompt))


if __name__ == '__main__':
    main()
