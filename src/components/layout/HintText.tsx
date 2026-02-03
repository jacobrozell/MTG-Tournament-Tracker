interface HintTextProps {
  message: string;
}

export function HintText({ message }: HintTextProps) {
  return <p className="text-sm text-gray-500 mt-1">{message}</p>;
}
