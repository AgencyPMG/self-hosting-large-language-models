#!/usr/bin/env python
"""
A small script to download a model from hugging face and save it locally.
"""

import typing
import argparse
import pathlib
from transformers import AutoTokenizer, AutoModel

def download_model(model_name: str, output_path: pathlib.Path):
    """
    Could drop this into a notebook to download the model in a specific
    environment (eg AWS sagemaker with inferentia)
    """
    if not output_path.exists():
        output_path.mkdir(parents=True)

    tokenizer = AutoTokenizer.from_pretrained(model_name)
    tokenizer.save_pretrained(str(output_path))

    model = AutoModel.from_pretrained(model_name)
    model.save_pretrained(str(output_path))


ArgsType = typing.Optional[typing.List[str]]

def parse_args(args: ArgsType=None) -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument('model_name', help='The model name to download')
    p.add_argument('output_path', type=pathlib.Path, help='where to save the model')

    return p.parse_args(args)
def main(args: ArgsType=None):
    args = parse_args(args)

    download_model(args.model_name, args.output_path)


if __name__ == '__main__':
    main()
