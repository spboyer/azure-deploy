export default function Home() {
  return (
    <div>
      <h1>Hello from Next.js SSR</h1>
      <p>Server-side rendered page</p>
    </div>
  );
}

export async function getServerSideProps() {
  return {
    props: {
      timestamp: new Date().toISOString(),
    },
  };
}
