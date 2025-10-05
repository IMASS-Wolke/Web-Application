import data from "../../assets/converted-outputs/fasst.json";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from "recharts";

export default function FaastGraph() {
  return (
    <ResponsiveContainer width="100%" height={600}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="Hr" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line type="monotone" dataKey="ATemp" stroke="#8884d8" />
        <Line type="monotone" dataKey="RH" stroke="#82ca9d" />
        <Line type="monotone" dataKey="WnSp" stroke="#ff7300" />
      </LineChart>
    </ResponsiveContainer>
  );
}
