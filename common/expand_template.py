import argparse
import sys
import pathlib


def main(args):
    parser = argparse.ArgumentParser(
        description='Generates new dst file by replacing given keys with given values in src file.')
    parser.add_argument('src', type=pathlib.Path,
                        help='Source file to use as a template')
    parser.add_argument('dst', type=pathlib.Path,
                        help='Destination file which to generate')
    parser.add_argument('replacements', type=str, nargs='+',
                        help='Key-value pairs for replacement in format: key0 value0 key1 value1...')

    args = parser.parse_args(args)

    if len(args.replacements) % 2 != 0:
        parser.error("Replacement must be in format: key0 value0 key1 value1...")

    template_args = [pair for pair in zip(*[iter(args.replacements)]*2)]

    with open(args.src, 'r') as source:
        template = source.read()
        for key, value in template_args:
            template = template.replace(key, value)

    with open(args.dst, 'w+') as dest:
        dest.write(template)


if __name__ == '__main__':
    main(sys.argv[1:])
